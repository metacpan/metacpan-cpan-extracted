package Locale::TextDomain::OO::Plugin::Expand::BabelFish::Loc::DomainAndCategory; ## no critic (TidyCode)

use strict;
use warnings;
use Locale::Utils::PlaceholderBabelFish;
use Moo::Role;

our $VERSION = '1.030';

with qw(
    Locale::TextDomain::OO::Plugin::Expand::BabelFish::Loc
    Locale::TextDomain::OO::Role::DomainAndCategory
);

requires qw(
    loc_b
    loc_bp

    begin_c
    begin_d
    begin_dc
    callback_scope
    end_c
    end_d
    end_dc
);

sub loc_bd {
    my ( $self, $domain, @more ) = @_;

    return $self->callback_scope(
        sub {
            $self->begin_d($domain);
            return $self->loc_b(@more);
        },
    );
}

sub loc_bc {
    my ($self, @more) = @_;

    return $self->callback_scope(
        sub {
            $self->begin_c( splice @more, 1, 1 );
            return $self->loc_b(@more);
        },
    );
}

sub loc_bdc {
    my ( $self, $domain, @more ) = @_;

    return $self->callback_scope(
        sub {
            $self->begin_d($domain);
            $self->begin_c( splice @more, 1, 1 );
            return $self->loc_bc(@more);
        },
    );
}

sub loc_bdp {
    my ( $self, $domain, @more ) = @_;

    return $self->callback_scope(
        sub {
            $self->begin_d($domain);
            return $self->loc_bp(@more);
        },
    );
}

sub loc_bcp {
    my ( $self, @more ) = @_;

    return $self->callback_scope(
        sub {
            $self->begin_c( splice @more, 2, 1 );
            return $self->loc_bp(@more);
        },
    );
}

sub loc_bdcp {
    my ( $self, $domain, @more ) = @_;

    return $self->callback_scope(
        sub {
            $self->begin_d($domain);
            $self->begin_c( splice @more, 2, 1 );
            return $self->loc_bcp(@more);
        },
    );
}

{
    no warnings qw(redefine); ## no critic (NoWarnings)

    # Dummy methods for string marking.
    my $dummy = sub {
        my (undef, @more) = @_;
        return wantarray ? @more : $more[0];
    };

    *loc_begin_bc  = \&begin_c;
    *loc_begin_bd  = \&begin_d;
    *loc_begin_bdc = \&begin_dc;

    *loc_end_bc  = \&end_c;
    *loc_end_bd  = \&end_d;
    *loc_end_bdc = \&end_dc;

    *Nloc_bd   = $dummy;
    *Nloc_bdp  = $dummy;

    *Nloc_bc   = $dummy;
    *Nloc_bcp  = $dummy;

    *Nloc_bdc   = $dummy;
    *Nloc_bdcp  = $dummy;
}

1;

__END__

=head1 NAME

Locale::TextDomain::OO::Plugin::Expand::BabelFish::Loc::DomainAndCategory - Methods for dynamic domain and/or category, prefixed with loc_b

$Id: DomainAndCategory.pm 651 2017-05-31 18:10:43Z steffenw $

$HeadURL: svn+ssh://steffenw@svn.code.sf.net/p/perl-gettext-oo/code/module/trunk/lib/Locale/TextDomain/OO/Plugin/Expand/Gettext/Loc/DomainAndCategory.pm $

=head1 VERSION

1.030

=head1 DESCRIPTION

This methods swiching the domain and/or category during translation process.

I am not sure if that is the best way to do.
Maybe that will change in future.

=head1 SYNOPSIS

    my $loc = Locale::Text::TextDomain::OO->new(
        plugins => [ qw (
            Expand::BabelFish::Loc::DomainAndCategory
            ...
        )],
        ...
    );

=head1 SUBROUTINES/METHODS

=head2 Switch methods

=head3 methods loc_begin_bd, loc_end_bd

Switch the domain.

    $loc->loc_begin_bd($domain);

All translations using the lexicon of that domain.

    $loc->loc_end_bd;

All translations using the lexicon before call of loc_begin_bd.

=head3 methods loc_begin_bc, loc_end_bc

Switch the category.

    $loc->loc_begin_bc($category);

All translations using the lexicon of that category.

    $loc->loc_end_bc;

All translations using the lexicon before call of loc_begin_bc.

=head3 methods loc_begin_bdc, loc_end_bdc

Switch the domain and category.

    $loc->loc_begin_bdc($domain, $category);

All translations using the lexicon of that domain and category.

    $loc->loc_end_bdc;

All translations using the lexicon before call of loc_begin_bdc.

=head2 Translation methods

=head3 methods loc_bd, loc_bdp

Switch to that domain, translate and switch back.

    $translation = $loc->loc_bd('domain', 'msgid', ...);

Other methods are similar extended.
The domain is the 1st parameter.

=head3 methods loc_bc, loc_bcp

Switch to that category, translate and switch back.

    $translation = $loc->loc_bc('msgid', 'category', ...);

Other methods are similar extended.
The category is the last parameter
but before the placeholder replacement parameters.

=head3 methods loc_bdc, loc_bdcp

Switch to that domain and category, translate and switch back both.

    $translation = $loc->loc_bdc('domain', 'msgid', 'category', ...);

Other methods are similar extended.
The domain is the 1st parameter.
The category is the last parameter
but before the placeholder replacement parameters.

=head3 methods Nloc_bd, Nloc_bdp

none translating methods with domain

=head3 methods Nloc_bc, Nloc_bcp

none translating methods with category

=head3 methods Nloc_bdc, Nloc_bdcp

none translating methods with domain and category

=head1 EXAMPLE

Inside of this distribution is a directory named example.
Run this *.pl files.

=head1 DIAGNOSTICS

nothing

=head1 CONFIGURATION AND ENVIRONMENT

none

=head1 DEPENDENCIES

L<Locale::Utils::PlaceholderBabelFish|Locale::Utils::PlaceholderBabelFish>

L<Moo::Role|Moo::Role>

L<Locale::TextDomain::OO::Plugin::Expand::BabelFish::Loc|Locale::TextDomain::OO::Plugin::Expand::BabelFish::Loc>

L<Locale::TextDomain::OO::Role::DomainAndCategory|Locale::TextDomain::OO::Role::DomainAndCategory>

=head1 INCOMPATIBILITIES

not known

=head1 BUGS AND LIMITATIONS

none

=head1 SEE ALSO

L<Locale::TextDoamin::OO|Locale::TextDoamin::OO>

=head1 AUTHOR

Steffen Winkler

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2017,
Steffen Winkler
C<< <steffenw at cpan.org> >>.
All rights reserved.

This module is free software;
you can redistribute it and/or modify it
under the same terms as Perl itself.
