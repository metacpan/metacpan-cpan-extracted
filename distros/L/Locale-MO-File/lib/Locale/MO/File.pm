package Locale::MO::File; ## no critic (TidyCode)

use strict;
use warnings;
use charnames qw(:full);
use namespace::autoclean;
use Carp qw(confess);
use Const::Fast qw(const);
use Encode qw(find_encoding);
use English qw(-no_match_vars $INPUT_RECORD_SEPARATOR $OS_ERROR);
require IO::File;
use Moo;
use MooX::StrictConstructor;
use MooX::Types::MooseLike::Base qw(Bool Str ArrayRef FileHandle);
use Params::Validate qw(validate_with SCALAR ARRAYREF);

our $VERSION = '0.08';

const my $INTEGER_LENGTH     => length pack 'N', 0;
const my $REVISION_OFFSET    => $INTEGER_LENGTH;
const my $MAPS_OFFSET        => $INTEGER_LENGTH * 7;
const my $MAGIC_NUMBER       => 0x95_04_12_DE;
const our $CONTEXT_SEPARATOR => "\N{END OF TRANSMISSION}";
const our $PLURAL_SEPARATOR  => "\N{NULL}";

has filename => (
    is      => 'rw',
    isa     => Str,
    reader  => 'get_filename',
    writer  => 'set_filename',
    clearer => 'clear_filename',
);
has file_handle => (
    is      => 'rw',
    isa     => FileHandle,
    reader  => 'get_file_handle',
    writer  => 'set_file_handle',
    clearer => 'clear_file_handle',
);
has encoding => (
    is      => 'rw',
    isa     => Str,
    reader  => 'get_encoding',
    writer  => 'set_encoding',
    clearer => 'clear_encoding',
);
has newline => (
    is      => 'rw',
    isa     => Str,
    reader  => 'get_newline',
    writer  => 'set_newline',
    clearer => 'clear_newline',
);
has is_big_endian => (
    is      => 'rw',
    isa     => Bool,
    reader  => 'is_big_endian',
    writer  => 'set_is_big_endian',
    clearer => 'clear_is_big_endian',
);
has messages => (
    is      => 'rw',
    isa     => ArrayRef,
    default => sub { return [] },
    lazy    => 1,
    reader  => 'get_messages',
    writer  => 'set_messages',
);

sub _encode_and_replace_newline {
    my ($self, $string) = @_;

    if ( $self->get_encoding ) {
        my $encoder = find_encoding( $self->get_encoding )
            or confess 'Can not find encoding for ', $self->get_encoding;
        $string = $encoder->encode($string);
    }
    if ( $self->get_newline ) {
        $string =~ s{ \r? \n }{ $self->get_newline }xmsge;
    }

    return $string;
}

sub _decode_and_replace_newline {
    my ($self, $string) = @_;

    if ( $self->get_encoding ) {
        my $encoder = find_encoding( $self->get_encoding )
            or confess 'Can not find encoding for ', $self->get_encoding;
        $string = $encoder->decode($string, Encode::FB_CROAK);
    }
    if ( $self->get_newline ) {
        $string =~ s{ \r? \n }{ $self->get_newline }xmsge;
    }

    return $string;
}

sub _pack_message {
    my ($self, $message) = @_;

    my ($msgid, $msgstr) = map {
        ( exists $message->{$_} && defined $message->{$_} )
        ? $message->{$_}
        : q{};
    } qw(msgid msgstr);

    # original
    $msgid = $self->_encode_and_replace_newline(
        (
            (
                exists $message->{msgctxt}
                && defined $message->{msgctxt}
                && length $message->{msgctxt}
            )
            ? $message->{msgctxt} . $CONTEXT_SEPARATOR . $msgid
            : $msgid
        )
        . (
            (
                exists $message->{msgid_plural}
                && defined $message->{msgid_plural}
                && length $message->{msgid_plural}
            )
            ? $PLURAL_SEPARATOR . $message->{msgid_plural}
            : q{}
        ),
    );

    # translation
    $msgstr = $self->_encode_and_replace_newline(
        length $msgstr
        ? $msgstr
        : join
            $PLURAL_SEPARATOR,
            map {
                defined $_ ? $_ : q{}
            } @{ $message->{msgstr_plural} || [] }
    );

    return {
        msgid  => $msgid,
        msgstr => $msgstr,
    };
}

sub _unpack_message {
    my ($self, $message) = @_;

    my ($msgid, $msgstr) = map {
        ( defined && length )
        ? $self->_decode_and_replace_newline($_)
        : q{};
    } @{$message}{qw(msgid msgstr)};

    # return value
    my %message;

    # split original
    my @strings = split m{ \Q$CONTEXT_SEPARATOR\E }xms, $msgid;
    if ( @strings > 1 ) {
        ( $message{msgctxt}, $msgid ) = @strings;
    }
    my @plurals = split m{ \Q$PLURAL_SEPARATOR\E }xms, $msgid;
    my $is_plural = @plurals > 1;
    if ( $is_plural ) {
        @message{qw(msgid msgid_plural)} = @plurals;
    }
    else {
        $message{msgid} = $msgid;
    }

    # split translation
    @plurals = split
        m{ \Q$PLURAL_SEPARATOR\E }xms,
        $msgstr,
        # get back also all hanging empty stings
        1 + do { my @separators = $msgstr =~ m{ \Q$PLURAL_SEPARATOR\E }xmsg };
    if ( $is_plural ) {
        $message{msgstr_plural} = \@plurals;
    }
    else {
        $message{msgstr} = $plurals[0];
    }

    return \%message;
}

before 'write_file' => sub {
    my $self = shift;

    my $index = 0;
    my $chars_callback = sub {
        my $string = shift;
        STRING: for ( ref $string ? @{$string} : $string ) {
            defined
                or next STRING;
            m{ \Q$CONTEXT_SEPARATOR\E | \Q$PLURAL_SEPARATOR\E }xmso
                and return;
        }
        return 1;
    };
    for my $message ( @{ $self->get_messages } ) {
        validate_with(
            params => (
                ref $message eq 'HASH'
                ? $message
                : confess "messages[$index] is not a hash reference"
            ),
            spec => {
                msgctxt => {
                    type      => SCALAR,
                    optional  => 1,
                    callbacks => {
                        'no control chars' => $chars_callback,
                    },
                },
                msgid => {
                    type      => SCALAR,
                    optional  => 1,
                    callbacks => {
                        'no control chars' => $chars_callback,
                    },
                },
                msgid_plural => {
                    type      => SCALAR,
                    optional  => 1,
                    callbacks => {
                        'no control chars' => $chars_callback,
                    },
                },
                msgstr => {
                    type      => SCALAR,
                    optional  => 1,
                    callbacks => {
                        'no control chars' => $chars_callback,
                    },
                },
                msgstr_plural => {
                    type      => ARRAYREF,
                    optional  => 1,
                    callbacks => {
                        'msgstr not set' => sub {
                            return ! (
                                exists $message->{msgstr_plural}
                                && exists $message->{msgstr}
                            );
                        },
                        'no control chars' => $chars_callback,
                    },
                },
            },
            called => "messages[$index]",
        );
        ++$index;
    }

    return $self;
};

sub write_file {
    my $self = shift;

    my $messages = [
        sort {
            $a->{msgid} cmp $b->{msgid};
        }
        map {
            $self->_pack_message($_);
        } @{ $self->get_messages }
    ];

    my $number_of_strings = @{$messages};

    # Set the byte order of the MO file creator
    my $template = $self->is_big_endian ? q{N} : q{V};

    my $maps    = q{};
    my $strings = q{};
    my $current_offset
        = $MAPS_OFFSET
        # length of map
        + $INTEGER_LENGTH * 4 * $number_of_strings; ## no critic (MagicNumbers)
    for my $key (qw(msgid msgstr)) {
        for my $message ( @{$messages} ) {
            my $string = $message->{$key};
            my $length = length $string;
            my $map = pack $template x 2, $length, $current_offset;
            $maps    .= $map;
            $string  .= $PLURAL_SEPARATOR;
            $strings .= $string;
            $current_offset += length $string;
        }
    }

    my $offset_original
        = $MAPS_OFFSET;
    my $offset_translated
        = $MAPS_OFFSET
        + $INTEGER_LENGTH * 2 * $number_of_strings;
    my $content
        = (
            pack $template x 7, ## no critic (MagicNumbers)
            $MAGIC_NUMBER,
            0, # revision
            $number_of_strings,
            $offset_original,
            $offset_translated,
            0, # hash size
            0, # hash offset
        )
        . $maps
        . $strings;

    my $filename = $self->get_filename;
    defined $filename
        or confess 'Filename not set';
    my $file_handle
        = $self->get_file_handle
        || IO::File->new($filename, '> :raw')
        || confess "Can not open mo file $filename $OS_ERROR";
    $file_handle->print($content)
        or confess "Can not write mo file $filename $OS_ERROR";
    if ( ! $self->get_file_handle ) {
        $file_handle->close
            or confess "Can not close mo file $filename $OS_ERROR";
    }

    return $self;
}

sub read_file {
    my $self = shift;

    my $filename = $self->get_filename;
    defined $filename
        or confess 'filename not set';
    my $file_handle
        = $self->get_file_handle
        || IO::File->new($filename, '< :raw')
        || confess "Can not open mo file $filename $OS_ERROR";
    my $content = do {
        local $INPUT_RECORD_SEPARATOR = ();
        <$file_handle>;
    };
    if ( ! $self->get_file_handle ) {
        $file_handle->close;
    }

    # Find the byte order of the MO file creator
    my $magic_number = substr $content, 0, $INTEGER_LENGTH;
    my $template =
        ( $magic_number eq pack 'V', $MAGIC_NUMBER )
        # Little endian
        ? q{V}
        : ( $magic_number eq pack 'N', $MAGIC_NUMBER )
        # Big endian
        ? q{N}
        # Wrong magic number. Not a valid MO file.
        : confess "MO file expected: $filename";

    my ($revision, $number_of_strings, $offset_original, $offset_translated)
        = unpack
            $template x 4, ## no critic (MagicNumbers)
            substr
                $content,
                $REVISION_OFFSET,
                $INTEGER_LENGTH * 4; ## no critic (MagicNumbers)
    $revision > 0
        and confess "Revision > 0 is unknown: $revision";

    $self->set_messages(\my @messages);
    for my $index (0 .. $number_of_strings - 1) {
        my $key = 'msgid';
        my $message;
        for my $offset ($offset_original, $offset_translated) {
            my ($string_length, $string_offset)
                = unpack
                    $template x 2,
                    substr
                        $content,
                        $offset + $index * $INTEGER_LENGTH * 2,
                        $INTEGER_LENGTH * 2;
            $message->{$key}
                = substr $content, $string_offset, $string_length;
            $key = 'msgstr';
        }
        $messages[$index] = $self->_unpack_message($message);
    }

    return $self;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Locale::MO::File - Write/read gettext MO files

$Id: File.pm 638 2017-10-01 19:05:33Z steffenw $

$HeadURL: svn+ssh://steffenw@svn.code.sf.net/p/dbd-po/code/Locale-MO-File/trunk/lib/Locale/MO/File.pm $

=head1 VERSION

0.08

=head1 SYNOPSIS

    require Locale::MO::File;

    my $mo = Locale::MO::File->new(
        filename => $filename,
        ...
        messages => [
            {
                msgid  => 'original',
                msgstr => 'translation',
                ...
            },
            ...
        ],
    });
    $mo->write_file;

    $mo->read_file;
    my $messages = $self->get_messages;

=head1 DESCRIPTION

The module allows to write or read gettext MO files.

Data to write are expected as array reference of hash references.
Read data are stored in an array reference too.

Reading and writing is also available using an already open file handle.
A given file handle will used but not closed.

Set encoding, newline and byte order to be compatible.

=head1 SUBROUTINES/METHODS

=head2 method new

This is the constructor method.
All parameters are optional.

    my $mo = Locale::MO::File->new(
        filename      => $string,
        file_handle   => $file_handle, # filename expected for error messages only
        encoding      => $string,      # e.g. 'UTF-8', if not set: bytes
        newline       => $string,      # e.g. $CRLF or "\n", if not set: no change
        is_big_endian => $boolean,     # if not set: little endian
        messages      => $arrayref,    # default []
    );

=head2 methods to modify an existing object

=head3 set_filename, get_filename, clear_filename

Modification of attribute filename.

    $mo->set_filename($string);
    $string = $mo->get_filename;
    $mo->clear_filename;

=head3 set_file_handle, get_file_handle, clear_file_handle

Modification of attribute file_handle.

=head3 set_encoding, get_encoding, clear_encoding

Modification of attribute encoding.

=head3 set_newline, get_newline, clear_newline

Modification of attribute newline.

=head3 set_is_big_endian, is_big_endian, clear_is_big_endian

Modification of attribute is_big_endian.
Only needed to write files.

=head2 method set_messages, get_messages

Modification of attribute messages.

    $mo->set_messages([
        # header
        {
            msgid   => q{},
            msgstr  => $header,
        },
        # typical
        {
            msgid   => $original,
            msgstr  => $translation,
        },
        # context
        {
            msgctxt => $context,
            msgid   => $original,
            msgstr  => $translation,
        },
        # plural
        {
            msgid         => $original_singular,
            msgid_plural  => $original_plural,
            msgstr_plural => [ $tanslation_0, ..., $translation_n ],
        },
        # context + plural
        {
            msgctxt       => $context,
            msgid         => $original_singular,
            msgid_plural  => $original_plural,
            msgstr_plural => [ $tanslation_0, ..., $translation_n ],
        },
    ]);

=head2 method write_file

The content of the "messages" array reference is first sorted and then written.
So the header is always on top.
The transferred "messages" array reference remains unchanged.

    $mo->write_file;

=head2 method read_file

Big endian or little endian will be detected automaticly.
The read data will be stored in attribute messages.

    $mo = read_file;
    my $messages = $mo->get_messages;

=head1 EXAMPLE

Inside of this distribution is a directory named example.
Run the *.pl files.

=head1 DIAGNOSTICS

Full validation of messages array reference using Params::Validate.

=head1 CONFIGURATION AND ENVIRONMENT

none

=head1 DEPENDENCIES

L<charnames|charnames>

L<namespace::autoclean|namespace::autoclean>

L<Carp|Carp>

L<Const::Fast|Const::Fast>

L<Encode|Encode>

L<English|English>

L<IO::File|IO::File>

L<Moo|Moo>

L<MooX::StrictConstructor|MooX::StrictConstructor>

L<MooX::Types::MooseLike::Base|MooX::Types::MooseLike::Base>

L<Params::Validate|Params::Validate>

=head1 INCOMPATIBILITIES

not known

=head1 BUGS AND LIMITATIONS

Hashing table not written of this module version.
So very slim MO files are the result.

=head1 SEE ALSO

L<http://www.gnu.org/software/hello/manual/gettext/MO-Files.html>

=head1 AUTHOR

Steffen Winkler

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2011 - 2017,
Steffen Winkler
C<< <steffenw at cpan.org> >>.
All rights reserved.

This module is free software;
you can redistribute it and/or modify it
under the same terms as Perl itself.
