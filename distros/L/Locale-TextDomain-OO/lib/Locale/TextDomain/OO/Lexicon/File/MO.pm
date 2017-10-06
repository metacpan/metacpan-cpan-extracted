package Locale::TextDomain::OO::Lexicon::File::MO; ## no critic (TidyCode)

use strict;
use warnings;
require Locale::MO::File;
use Moo;
use MooX::StrictConstructor;
use namespace::autoclean;

our $VERSION = '1.031';

with qw(
    Locale::TextDomain::OO::Lexicon::Role::File
);

sub read_messages {
    my ($self, $filename) = @_;

    return Locale::MO::File
        ->new( filename => $filename )
        ->read_file
        ->get_messages;
}

1;

__END__

=head1 NAME

Locale::TextDomain::OO::Lexicon::File::MO - Gettext mo file as lexicon

$Id: MO.pm 698 2017-09-28 05:21:05Z steffenw $

$HeadURL: svn+ssh://steffenw@svn.code.sf.net/p/perl-gettext-oo/code/module/trunk/lib/Locale/TextDomain/OO/Lexicon/File/MO.pm $

=head1 VERSION

1.031

=head1 DESCRIPTION

This module reads a gettext mo file into the lexicon.

=head1 SYNOPSIS

    use Locale::TextDomain::OO::Lexicon::File::MO;
    use Log::Any qw($log);

    $logger = Locale::TextDomain::OO::Lexicon::File::MO
        ->new(
            # all parameters are optional
            decode_code => sub {
                my ($charset, $text) = @_;
                defined $text
                    or return $text;
                return decode( $charset, $text );
            },
            # optional
            logger => sub {
                my ($message, $arg_ref) = @_;
                my $type = $arg_ref->{type}; # debug
                $log->$type($message);
                return;
            },
        )
        ->lexicon_ref({
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

                # Copy a lexicon into another domain and/or category:
                copy_lexicon => 'i-default::' => 'i-default:LC_MESSAGES:domain',

                # Move a lexicon into another domain and/or category:
                move_lexicon => 'i-default::' => 'i-default:LC_MESSAGES:domain',

                # Delete a lexicon:
                delete_lexicon => 'i-default::',
            ],
        })
        ->logger;

=head1 SUBROUTINES/METHODS

=head2 method new

see SYNOPSIS

=head2 method lexicon_ref

See SYNOPSIS.

=head2 method read_messages

Called from Locale::TextDomain::OO::Lexicon::Role::File
to run the mo file specific code.

    $messages_ref = $self->read_messages($filename);

=head2 method logger

Set the logger and get back them

    $lexicon_file_mo->logger(
        sub {
            my ($message, $arg_ref) = @_;
            my $type = $arg_ref->{type};
            $log->$type($message);
            return;
        },
    );
    $logger = $lexicon_hash->logger;

$arg_ref contains

    object => $lexicon_file_mo, # the object itself
    type   => 'debug',
    event  => 'lexicon,load', # The logger will be copied to
                              # Locale::TextDomain::OO::Singleton::Lexicon
                              # so more events are possible.

=head1 EXAMPLE

Inside of this distribution is a directory named example.
Run this *.pl files.

=head1 DIAGNOSTICS

none

=head1 CONFIGURATION AND ENVIRONMENT

none

=head1 DEPENDENCIES

L<Locale::MO::File|Locale::MO::File>

L<Moo|Moo>

L<MooX::StrictConstructor|MooX::StrictConstructor>

L<Locale::TextDomain::OO::Lexicon::Role::File|Locale::TextDomain::OO::Lexicon::Role::File>

=head1 INCOMPATIBILITIES

not known

=head1 BUGS AND LIMITATIONS

none

=head1 SEE ALSO

L<Locale::TextDoamin::OO|Locale::TextDoamin::OO>

=head1 AUTHOR

Steffen Winkler

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2013 - 2017,
Steffen Winkler
C<< <steffenw at cpan.org> >>.
All rights reserved.

This module is free software;
you can redistribute it and/or modify it
under the same terms as Perl itself.
