package Locale::TextDomain::OO::Lexicon::Hash; ## no critic (TidyCode)

use strict;
use warnings;
use Carp qw(confess);
use Locale::TextDomain::OO::Singleton::Lexicon;
use Locale::TextDomain::OO::Util::ExtractHeader;
use Locale::TextDomain::OO::Util::JoinSplitLexiconKeys;
use Moo;
use MooX::StrictConstructor;
use namespace::autoclean;

our $VERSION = '1.026';

with qw(
    Locale::TextDomain::OO::Role::Logger
);

sub lexicon_ref {
    my ($self, $hash_lexicon) = @_;

    ref $hash_lexicon eq 'HASH'
        or confess 'The given lexicon should be a hash reference';
    my $lexicon  = Locale::TextDomain::OO::Singleton::Lexicon->instance->data;
    my $key_util = Locale::TextDomain::OO::Util::JoinSplitLexiconKeys->instance;
    while ( my ($lexicon_key, $lexicon_value) = each %{$hash_lexicon} ) {
        my $header = $lexicon_value->[0];
        my $header_msgstr = $header->{msgstr}
            or confess 'msgstr of header not found';
        $lexicon_value->[0] = Locale::TextDomain::OO::Util::ExtractHeader
            ->instance
            ->extract_header_msgstr($header_msgstr);
        my $nplurals = $lexicon_value->[0]->{nplurals};
        VALUE:
        for my $value ( @{$lexicon_value} ) {
            # move to lexicon
            my $msg_key = $key_util->join_message_key({
                msgctxt      => delete $value->{msgctxt},
                msgid        => my $msgid        = delete $value->{msgid},
                msgid_plural => my $msgid_plural = delete $value->{msgid_plural},
            });
            $lexicon->{$lexicon_key}->{$msg_key} = $value;
            # structure faults
            exists $value->{msgstr_plural}
                or next VALUE;
            my $plural_count = @{ $value->{msgstr_plural} };
            $plural_count <= $nplurals or confess sprintf
                'Count of msgstr_plural=%s but nplurals=%s for msgid="%s" msgid_plural="%s"',
                $plural_count,
                $nplurals,
                ( defined $msgid        ? $msgid        : q{} ),
                ( defined $msgid_plural ? $msgid_plural : q{} );
        }
        $self->logger
            and $self->logger->(
                qq{Lexicon "$lexicon_key" loaded from hash.},
                {
                    object => $self,
                    type   => 'debug',
                    event  => 'lexicon,load',
                },
            );
    }

    return;
}

1;

__END__

=head1 NAME

Locale::TextDomain::OO::Lexicon::Hash - Lexicon from data structure

$Id: Hash.pm 618 2015-08-22 18:02:42Z steffenw $

$HeadURL: svn+ssh://steffenw@svn.code.sf.net/p/perl-gettext-oo/code/module/trunk/lib/Locale/TextDomain/OO/Lexicon/Hash.pm $

=head1 VERSION

1.026

=head1 DESCRIPTION

This module allows to create a lexicon from data structure.

=head1 SYNOPSIS

    require Locale::TextDomain::OO::Lexicon::Hash;

    Locale::TextDomain::OO::Lexicon::Hash
        ->new(
            # all parameters are optional
            logger => sub {
                my ($message, $arg_ref) = @_;
                my $type = $arg_ref->{type}; # debug
                Log::Log4perl->get_logger(...)->$type($message);
                return;
            },
        )
        ->lexicon_ref({ ... });

=head1 SUBROUTINES/METHODS

=head2 method new

see SYNOPSIS

=head2 method lexicon_ref

Fill in lexicon data from Perl data structure.

For language "de-de", no category (default) and no domain (default)
the lexicon name is "de-de::".

For language "en", category "LC_MESSAGES" and domain "test"
the lexicon name is "en:LC_MESSAGES:test".

The keys of each item are stolen from PO file.
Except the keys "msgstr_plural[0]", "msgstr_plural[1]", ... "msgstr_plural[N]"
are written as key "msgstr_plural" with an array reference as value.

    $self->lexicon_ref({
        'de:MyCategory:MyDomain' . ':OptionalProject' => [
            # header in a very minimalistic form
            {
                msgid  => "",
                msgstr => ""
                    . "Content-Type: text/plain; charset=UTF-8\n"
                    . "Plural-Forms: nplurals=2; plural=n != 1;",
            },
            # single translation
            {
                msgid  => "help",
                msgstr => "Hilfe",
            },
            # with context
            {
                msgctxt => "datetime",
                msgid   => "date",
                msgstr  => "Datum",
            },
            # plural
            {
                msgid         => "person",
                msgid_plural  => "persons",
                msgstr_plural => [
                    "Person",
                    "Personen",
                ],
            },
            # plural with context
            {
                msgctxt       => "appointment",
                msgid         => "date",
                msgid_plural  => "dates",
                msgstr_plural => [
                    "Date",
                    "Dates",
                ],
            },
        ],
    });

=head2 method logger

Set the logger

    $lexicon_hash->logger(
        sub {
            my ($message, $arg_ref) = @_;
            my $type = $arg_ref->{type};
            Log::Log4perl->get_logger(...)->$type($message);
            return;
        },
    );

$arg_ref contains

    object => $lexicon_hash, # the object itself
    type   => 'debug',
    event  => 'lexicon,load',

=head1 EXAMPLE

Inside of this distribution is a directory named example.
Run this *.pl files.

=head1 DIAGNOSTICS

confess

=head1 CONFIGURATION AND ENVIRONMENT

none

=head1 DEPENDENCIES

L<Carp|Carp>

L<Locale::TextDomain::OO::Singleton::Lexicon|Locale::TextDomain::OO::Singleton::Lexicon>

L<Locale::TextDomain::OO::Util::ExtractHeader|Locale::TextDomain::OO::Util::ExtractHeader>

L<Locale::TextDomain::OO::Util::JoinSplitLexiconKeys|Locale::TextDomain::OO::Util::JoinSplitLexiconKeys>

L<Moo|Moo>

L<MooX::StrictConstructor|MooX::StrictConstructor>

L<namespace::autoclean|namespace::autoclean>

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
