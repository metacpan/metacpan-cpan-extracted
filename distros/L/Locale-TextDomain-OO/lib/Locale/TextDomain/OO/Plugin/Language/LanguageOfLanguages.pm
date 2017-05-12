package Locale::TextDomain::OO::Plugin::Language::LanguageOfLanguages; ## no critic (Tidy Code)

use strict;
use warnings;
use Locale::TextDomain::OO::Singleton::Lexicon;
use Locale::TextDomain::OO::Util::JoinSplitLexiconKeys;
use Moo::Role;
use MooX::Types::MooseLike::Base qw(Str ArrayRef);
use namespace::autoclean;

our $VERSION = '1.014';

with qw(
    Locale::TextDomain::OO::Role::Logger
);

requires qw(
    language
    category
    domain
    project
);

has languages => (
    is      => 'rw',
    isa     => ArrayRef[Str],
    trigger => 1,
    lazy    => 1,
    default => sub { [] },
);

sub _trigger_languages { ## no critic (UnusedPrivateSubroutines)
    my ($self, $languages) = @_;

    my $lexicon = Locale::TextDomain::OO::Singleton::Lexicon->instance->data;
    for my $language ( @{$languages} ) {
        for my $key ( keys %{$lexicon} ) {
            my $lexicon_key = Locale::TextDomain::OO::Util::JoinSplitLexiconKeys
                ->instance
                ->join_lexicon_key({
                    language => lc $language,
                    category => $self->category,
                    domain   => $self->domain,
                    project  => $self->project,
                });
            if ( $key eq $lexicon_key ) {
                $self->language( lc $language );
                return;
            }
        }
    }
    $self->language('i-default');
    $self->logger
        and $self->logger->(
            'Fallback language "i-default" selected.',
            {
                object => $self,
                type   => 'warn',
                event  => 'language,selection,fallback',
            },
        );

    return;
}

1;

__END__

=head1 NAME

Locale::TextDomain::OO::Plugin::Language::LanguageOfLanguages - Select a language of a list

$Id: LanguageOfLanguages.pm 603 2015-08-09 16:46:25Z steffenw $

$HeadURL: svn+ssh://steffenw@svn.code.sf.net/p/perl-gettext-oo/code/module/trunk/lib/Locale/TextDomain/OO/Plugin/Language/LanguageOfLanguages.pm $

=head1 VERSION

1.014

=head1 DESCRIPTION

This plugin provides the languages method.
After set of languages it will find and set the first language match in lexicon.
Otherwise language is set to i-default.

=head1 SYNOPSIS

    $loc = Locale::TextDomain::OO->new(
        plugins => [ qw (
            Language::LanguageOfLanguages
            ...
        ) ],
        ...
    );

=head1 SUBROUTINES/METHODS

=head2 method languages

E.g. if exists no lexicon for "de-de" but one for "de"
the language is set to "de";

    $loc->languages([ qw( de-de de en ) ]);

And read back what languages are set.

    $languages_ref = $loc->languages;

=head1 EXAMPLE

Inside of this distribution is a directory named example.
Run this *.pl files.

=head1 DIAGNOSTICS

none

=head1 CONFIGURATION AND ENVIRONMENT

none

=head1 DEPENDENCIES

L<Locale::TextDomain::OO::Singleton::Lexicon|Locale::TextDomain::OO::Singleton::Lexicon>

L<Locale::TextDomain::OO::Util::JoinSplitLexiconKeys|Locale::TextDomain::OO::Util::JoinSplitLexiconKeys>

L<Moo::Role|Moo::Role>

L<MooX::Types::MooseLike::Base|MooX::Types::MooseLike::Base>

L<namespace::autoclean|namespace::autoclean>

=head1 INCOMPATIBILITIES

not known

=head1 BUGS AND LIMITATIONS

none

=head1 SEE ALSO

L<Locale::TextDoamin::OO|Locale::TextDoamin::OO>

=head1 AUTHOR

Steffen Winkler

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2013 - 2014,
Steffen Winkler
C<< <steffenw at cpan.org> >>.
All rights reserved.

This module is free software;
you can redistribute it and/or modify it
under the same terms as Perl itself.
