package Locale::File::PO::Header; ## no critic (TidyCode)

use Moose;
use MooseX::StrictConstructor;

use namespace::autoclean;
use syntax qw(method);

require Locale::File::PO::Header::Item;
require Locale::File::PO::Header::MailItem;
require Locale::File::PO::Header::ContentTypeItem;
require Locale::File::PO::Header::ExtendedItem;

our $VERSION = '0.003';

has _header => (
    is       => 'rw',
    init_arg => undef,
    lazy     => 1,
    default  => \&_default_header,
);

has _header_index => (
    is       => 'ro',
    init_arg => undef,
    lazy     => 1,
    default  => method {
        my %header_index;
        my $index = 0;
        for my $item ( @{ $self->_header } ) {
            for my $key ( $item->header_keys ) {
                $header_index{$key} = $index;
            }
            $index++;
        }

        return \%header_index;
    },
);

method _default_header {
    return [
        Locale::File::PO::Header::Item->new(
            name => 'Project-Id-Version',
        ),
        Locale::File::PO::Header::MailItem->new(
            name => 'Report-Msgid-Bugs-To',
        ),
        Locale::File::PO::Header::Item->new(
            name => 'POT-Creation-Date',
        ),
        Locale::File::PO::Header::Item->new(
            name => 'PO-Revision-Date',
        ),
        Locale::File::PO::Header::MailItem->new(
            name => 'Last-Translator',
        ),
        Locale::File::PO::Header::MailItem->new(
            name => 'Language-Team',
        ),
        Locale::File::PO::Header::Item->new(
            name    => 'MIME-Version',
            default => '1.0',
        ),
        Locale::File::PO::Header::ContentTypeItem->new(
            name    => 'Content-Type',
            default => {
                'Content-Type' => 'text/plain',
                charset        => 'ISO-8859-1',
            },
        ),
        Locale::File::PO::Header::Item->new(
            name    => 'Content-Transfer-Encoding',
            default => '8bit',
        ),
        Locale::File::PO::Header::Item->new(
            name => 'Plural-Forms',
        ),
        Locale::File::PO::Header::ExtendedItem->new(
            name => 'extended',
        ),
    ];
}

# get only
method all_keys {
    return map {
        $_->header_keys;
    } @{ $self->_header };
}

# set only
method data ($data) {
    ref $data eq 'HASH'
        or confess 'Hash reference expected';
    $self->_header( $self->_default_header );
    for my $key ( keys %{$data} ) {
        my $value = delete $data->{$key};
        if ( defined $value && length $value ) {
            my $index = $self->_header_index->{$key};
            defined $index
                or confess "Unknown key $key";
            my $item = $self->_header->[$index]->data($key, $value);
        }
    }

    return;
}

method item ($key, $value) {
    defined $key
        or confess 'Undefined key';
    my $index = $self->_header_index->{$key};
    defined $index
        or confess "Unknown key $key";
    my $item = $self->_header->[$index];
    # set
    if ( defined $value && length $value ) {
        return $item->data($key, $value);
    }

    # get
    return $item->data($key);
}

# get only
method items (@args) {
    return map { $self->item($_) } @args;
}

method msgstr (@args) {
    # set
    if (@args) {
        my $msgstr = defined $args[0] ? $args[0] : q{};
        for my $item ( @{ $self->_header } ) {
            $item->extract_msgstr(\$msgstr);
        }
        return;
    }

    # get
    return join "\n", map { $_->lines } @{ $self->_header };
}

__PACKAGE__->meta->make_immutable;

# $Id:$

1;

__END__

=head1 NAME

Locale::File::PO::Header - Utils to build/extract the PO header

$Id: Utils.pm 602 2011-11-13 13:49:23Z steffenw $

$HeadURL: https://dbd-po.svn.sourceforge.net/svnroot/dbd-po/Locale-File-PO-Header/trunk/lib/Locale/PO/Utils.pm $

=head1 VERSION

0.003

=head1 SYNOPSIS

    require Locale::PO::Utils;

    $obj = Locale::PO::Utils->new;

=head1 DESCRIPTION

Utils to build or extract the PO header

The header of a PO file is quite complex.
This module helps to build the header and extract.

=head1 SUBROUTINES/METHODS

=head2 method msgstr - read and write the header as string

=head3 reader

    $msgstr = $obj->msgstr;

If nothing was set before it returns a minimal header:

 MIME-Version: 1.0
 Content-Type: text/plain; charset=ISO-8859-1
 Content-Transfer-Encoding: 8bit

=head3 writer

    $obj->msgstr(<<'EOT');
        Content-Type: text/plain; charset=UTF-8
    EOT

If nothing else was set before the msgstr is:

 MIME-Version: 1.0
 Content-Type: text/plain; charset=UTF-8
 Content-Transfer-Encoding: 8bit

=head2 method all_keys - names of all items

This sub returns all header keys you can set or get.

    @all_keys = $obj->all_keys;

The returned array is:

    qw(
        Project-Id-Version
        Report-Msgid-Bugs-To_name
        Report-Msgid-Bugs-To_address
        POT-Creation-Date
        PO-Revision-Date
        Last-Translator_name
        Last-Translator_address
        Language-Team_name
        Language-Team_address
        MIME-Version
        Content-Type
        charset
        Content-Transfer-Encoding
        Plural-Forms
        extended
    )

=head2 method data - modify lots of items

    $obj->data({
        Project-Id-Version           => 'Example',
        Report-Msgid-Bugs-To_address => 'bug@example.com',
        extended                     => {
            X-Example => 'This is an example',
        },
    });

If nothing else was set before the msgstr is:

 Project-Id-Version: Example
 Report-Msgid-Bugs-To: bug@example.com
 MIME-Version: 1.0
 Content-Type: text/plain; charset=ISO-8859-1
 Content-Transfer-Encoding: 8bit
 X-Example: This is an example

An example to write all keys:

    $obj->data({
        'Project-Id-Version'           => 'Testproject',
        'Report-Msgid-Bugs-To_name'    => 'Bug Reporter',
        'Report-Msgid-Bugs-To_address' => 'bug@example.org',
        'POT-Creation-Date'            => 'no POT creation date',
        'PO-Revision-Date'             => 'no PO revision date',
        'Last-Translator_name'         => 'Steffen Winkler',
        'Last-Translator_address'      => 'steffenw@example.org',
        'Language-Team_name'           => 'MyTeam',
        'Language-Team_address'        => 'cpan@example.org',
        'MIME-Version'                 => '1.0',
        'Content-Type'                 => 'text/plain',
        'charset'                      => 'utf-8',
        'Content-Transfer-Encoding'    => '8bit',
        'extended'                     => [
            'X-Poedit-Language'      => 'German',
            'X-Poedit-Country'       => 'GERMANY',
            'X-Poedit-SourceCharset' => 'utf-8',
        ],
    });

The msgstr is:

 Project-Id-Version: Testproject
 Report-Msgid-Bugs-To: Bug Reporter <bug@example.org>
 POT-Creation-Date: no POT creation date
 PO-Revision-Date: no PO revision date
 Last-Translator: Steffen Winkler <steffenw@example.org>
 Language-Team: MyTeam <cpan@example.org>
 MIME-Version: 1.0
 Content-Type: text/plain; charset=utf-8
 Content-Transfer-Encoding: 8bit
 X-Poedit-Language: German
 X-Poedit-Country: GERMANY
 X-Poedit-SourceCharset: utf-8

=head2 method item - read or write one item

=head3 writer

   $obj->item( 'Project-Id-Version' => 'Example' );

=head3 reader

   $value = $obj->item('Project-Id-Version');

=head2 method items - read lots of items

    @values = $obj->items( @keys );

    @values = $obj->items( qw(Project-Id-Version charset) );

=head1 EXAMPLE

Inside of this distribution is a directory named example.
Run the *.pl files.

=head1 DIAGNOSTICS

none

=head1 CONFIGURATION AND ENVIRONMENT

none

=head1 DEPENDENCIES

L<Moose|Moose>

L<MooseX::StrictConstructor|MooseX::StrictConstructor>

L<namespace::autoclean|namespace::autoclean>;

L<syntax|syntax>

L<Clone|Clone>

=head1 INCOMPATIBILITIES

not known

=head1 BUGS AND LIMITATIONS

not known

=head1 SEE ALSO

L<http://en.wikipedia.org/wiki/Gettext>

=head1 AUTHOR

Steffen Winkler

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2011 - 2012,
Steffen Winkler
C<< <steffenw at cpan.org> >>.
All rights reserved.

This module is free software;
you can redistribute it and/or modify it
under the same terms as Perl itself.
