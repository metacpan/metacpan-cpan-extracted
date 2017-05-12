package Locale::TextDomain::OO::Lexicon::Role::File; ## no critic (TidyCode)

use strict;
use warnings;
use Carp qw(confess);
use Encode qw(decode FB_CROAK);
use English qw(-no_match_vars $OS_ERROR);
use Locale::TextDomain::OO::Singleton::Lexicon;
use Locale::TextDomain::OO::Util::ExtractHeader;
use Locale::TextDomain::OO::Util::JoinSplitLexiconKeys;
use Moo::Role;
use MooX::Types::MooseLike::Base qw(CodeRef);
use Path::Tiny qw(path);
use namespace::autoclean;

our $VERSION = '1.023';

with qw(
    Locale::TextDomain::OO::Lexicon::Role::GettextToMaketext
    Locale::TextDomain::OO::Role::Logger
);

requires qw(
    read_messages
);

has decode_code => (
    is      => 'ro',
    isa     => CodeRef,
    lazy    => 1,
    default => sub {
        sub {
            my ($charset, $text) = @_;
            defined $text
                or return $text;

            return decode( $charset, $text, FB_CROAK );
        };
    },
);

sub _decode_messages {
    my ($self, $messages_ref) = @_;

    my $charset = lc $messages_ref->[0]->{charset};
    for my $value ( @{$messages_ref} ) {
        for my $key ( qw( msgid msgid_plural msgstr ) ) {
            if ( exists $value->{$key} ) {
                for my $text ( $value->{$key} ) {
                    $text = $self->decode_code->($charset, $text);
                }
            }
        }
        if ( exists $value->{msgstr_plural} ) {
            my $got      = @{ $value->{msgstr_plural} };
            my $expected = $messages_ref->[0]->{nplurals};
            $got <= $expected or confess sprintf
                'Count of msgstr_plural=%s but nplurals=%s for msgid="%s" msgid_plural="%s"',
                $got,
                $expected,
                ( exists $value->{msgid}        ? $value->{msgid}        : q{} ),
                ( exists $value->{msgid_plural} ? $value->{msgid_plural} : q{} );
            for my $text ( @{ $value->{msgstr_plural} } ) {
                $text = $self->decode_code->($charset, $text);
            }
        }
    }

    return;
}

sub _my_glob {
    my ($self, $file) = @_;

    my $dirname  = $file->dirname;
    my $filename = $file->basename;

    # only one * allowed at all
    my $dir_star_count  = () = $dirname  =~ m{ [*] }xmsg;
    my $file_star_count = () = $filename =~ m{ [*] }xmsg;
    my $count = $dir_star_count + $file_star_count;
    $count
        or return $file;
    $count > 1
        and confess 'Only one * in dirname/filename is allowd to reference the language';

    # one * in filename
    if ( $file_star_count ) {
        ( my $file_regex = quotemeta $filename ) =~ s{\\[*]}{.*?}xms;
        return +(
            sort +path($dirname)->children( qr{\A $file_regex \z}xms )
        );
    }

    # one * in dir
    # split that dir into left, inner with * and right
    my ( $left_dir, $inner_dir, $right_dir )
        = split qr{( [^/*]* [*] [^/]* )}xms, $dirname;
    ( my $inner_dir_regex = quotemeta $inner_dir ) =~ s{\\[*]}{.*?}xms;
    my @left_and_inner_dirs
        = path($left_dir)->children( qr{$inner_dir_regex}xms );

    return +(
        sort
        grep {
            $_->is_file;
        }
        map {
            path($_, $right_dir, $filename);
        }
        @left_and_inner_dirs
    );
}

sub _run_extra_commands {
    my ($self, $identifier, $instance, $next_data_code) = @_;

    if ( $identifier eq 'merge_lexicon' ) {
        my ( $from1, $from2, $to ) = (
            $next_data_code->(),
            $next_data_code->(),
            $next_data_code->(),
        );
        $instance->merge_lexicon( $from1, $from2, $to );
        $self->logger and $self->logger->(
            qq{Lexicon "$from1", "$from2" merged to "$to".},
            {
                object => $self,
                type   => 'debug',
                event  => 'lexicon,merge',
            },
        );
        return 1;
    }
    if ( $identifier eq 'move_lexicon' ) {
        my ( $from, $to ) = ( $next_data_code->(), $next_data_code->() );
        $instance->move_lexicon( $from, $to );
        $self->logger and $self->logger->(
            qq{Lexicon "$from" moved to "$to".},
            {
                object => $self,
                type   => 'debug',
                event  => 'lexicon,move',
            },
        );
        return 1;
    }
    if ( $identifier eq 'delete_lexicon' ) {
        my $name = $next_data_code->();
        $instance->delete_lexicon($name);
        $self->logger and $self->logger->(
            qq{Lexicon "$name" deleted.},
            {
                object => $self,
                type   => 'debug',
                event  => 'lexicon,delete',
            },
        );
        return 1;
    }

    return;
}

sub lexicon_ref {
    my ($self, $file_lexicon_ref) = @_;

    my $instance = Locale::TextDomain::OO::Singleton::Lexicon->instance;
    my $search_dirs = $file_lexicon_ref->{search_dirs}
        or confess 'Hash key "search_dirs" expected';
    my $header_util = Locale::TextDomain::OO::Util::ExtractHeader->instance;
    my $key_util    = Locale::TextDomain::OO::Util::JoinSplitLexiconKeys->instance;
    my $data = $file_lexicon_ref->{data};
    my $index = 0;
    DATA:
    while ( $index < @{ $file_lexicon_ref->{data} } ) {
        my $identifier = $data->[ $index++ ];
        $self->_run_extra_commands(
            $identifier,
            $instance,
            sub { return $data->[ $index++ ] },
        ) and next DATA;
        my ( $lexicon_key, $lexicon_value )
            = ( $identifier, $data->[ $index++ ] );
        for my $dir ( @{ $search_dirs } ) {
            my $file = path( $dir, $lexicon_value );
            my @files = $self->_my_glob($file);
            for ( @files ) {
                my $filename = $_->canonpath;
                my $lexicon_language_key = $lexicon_key;
                my $language = $filename;
                my @parts = split m{[*]}xms, $file;
                if ( @parts == 2 ) {
                    substr $language, 0, length $parts[0], q{};
                    substr $language, - length $parts[1], length $parts[1], q{};
                    $lexicon_language_key =~ s{[*]}{$language}xms;
                }
                my $messages_ref = $self->read_messages($filename);
                my $header_msgstr = $messages_ref->[0]->{msgstr}
                    or confess 'msgstr of header not found';
                my $header_ref = $messages_ref->[0];
                %{$header_ref} = (
                    msgid => $header_ref->{msgid},
                    %{ $header_util->extract_header_msgstr( $header_ref->{msgstr} ) },
                );
                $file_lexicon_ref->{gettext_to_maketext}
                    and $self->gettext_to_maketext($messages_ref);
                $file_lexicon_ref->{decode}
                    and $self->_decode_messages($messages_ref);
                $instance->data->{$lexicon_language_key} = {
                    map { ## no critic (ComplexMappings)
                        my $message_ref = $_;
                        my $msg_key = $key_util->join_message_key({(
                            map {
                                $_ => delete $message_ref->{$_};
                            }
                            qw( msgctxt msgid msgid_plural )
                        )});
                        ( $msg_key => $message_ref );
                    } @{$messages_ref}
                };
                $self->logger and $self->logger->(
                    qq{Lexicon "$lexicon_language_key" loaded from file "$filename".},
                    {
                        object => $self,
                        type   => 'debug',
                        event  => 'lexicon,load',
                    },
                );
            }
        }
    }

    return $self;
}

1;

__END__

=head1 NAME

Locale::TextDomain::OO::Lexicon::Role::File - Helper role to add lexicon from file

$Id: File.pm 617 2015-08-22 05:39:27Z steffenw $

$HeadURL: svn+ssh://steffenw@svn.code.sf.net/p/perl-gettext-oo/code/module/trunk/lib/Locale/TextDomain/OO/Lexicon/Role/File.pm $

=head1 VERSION

1.023

=head1 DESCRIPTION

This module provides methods to inplmement lexicon from file easy.

=head1 SYNOPSIS

    with qw(
        Locale::TextDomain::OO::Lexicon::Role::File
    );

=head1 SUBROUTINES/METHODS

=head2 attribute decode_code

Allows to implement your own way of decode messages.
Add a code ref in constructor.

    decode_code => sub {
        my ($charset, $text) = @_;
        defined $text
            or return $text;

        return decode( $charset, $text );
    },

=head2 method lexicon_ref

    $self->lexicon_ref({
        # required
        search_dirs => [ qw( ./my_dir ./my_other_dir ) ],
        # optional
        gettext_to_maketext => $boolean,
        # optional
        decode => $boolean,
        # required
        data => [
            # e.g. de.mo, en.mo read from:
            # search_dir/de.mo
            # search_dir/en.mo
            '*::' => '*.mo',

            # e.g. de.mo en.mo read from:
            # search_dir/subdir/de/LC_MESSAGES/domain.mo
            # search_dir/subdir/en/LC_MESSAGES/domain.mo
            '*:LC_MESSAGES:domain' => 'subdir/*/LC_MESSAGES/domain.mo',

            # Merge a region lexicon:
            # Take the header and messages of the "de::" lexicon,
            # overwrite the header and messages of the "de-at::" lexicon
            # and store that as "de-at::" lexicon with all messages now.
            merge_lexicon => 'de::', 'de-at::' => 'de-at::',

            # Move a lexicon into another domain and/or category:
            move_lexicon => 'i-default::' => 'i-default:LC_MESSAGES:domain',

            # Delete a lexicon:
            delete_lexicon => 'i-default::',
        ],
    });

=head1 EXAMPLE

Inside of this distribution is a directory named example.
Run this *.pl files.

=head1 DIAGNOSTICS

confess

=head1 CONFIGURATION AND ENVIRONMENT

none

=head1 DEPENDENCIES

L<Carp|Carp>

L<Encode|Encode>

L<English|English>

L<Locale::TextDomain::OO::Singleton::Lexicon|Locale::TextDomain::OO::Singleton::Lexicon>

L<Locale::TextDomain::OO::Util::ExtractHeader|Locale::TextDomain::OO::Util::ExtractHeader>

L<Locale::TextDomain::OO::Util::JoinSplitLexiconKeys|Locale::TextDomain::OO::Util::JoinSplitLexiconKeys>

L<Moo::Role|Moo::Role>

L<MooX::Types::MooseLike::Base|MooX::Types::MooseLike::Base>

L<Path::Tiny|Path::Tiny>

L<namespace::autoclean|namespace::autoclean>

L<Locale::TextDomain::OO::Lexicon::Role::GettextToMaketext|Locale::TextDomain::OO::Lexicon::Role::GettextToMaketext>

L<Locale::TextDomain::OO::Role::Logger|Locale::TextDomain::OO::Role::Logger>

=head1 INCOMPATIBILITIES

not known

=head1 BUGS AND LIMITATIONS

none

=head1 SEE ALSO

L<Locale::TextDoamin::OO|Locale::TextDoamin::OO>

=head1 AUTHOR

Steffen Winkler

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2013 - 2015,
Steffen Winkler
C<< <steffenw at cpan.org> >>.
All rights reserved.

This module is free software;
you can redistribute it and/or modify it
under the same terms as Perl itself.
