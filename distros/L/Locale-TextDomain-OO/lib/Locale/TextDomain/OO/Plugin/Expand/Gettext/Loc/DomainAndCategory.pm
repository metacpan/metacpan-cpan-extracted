package Locale::TextDomain::OO::Plugin::Expand::Gettext::Loc::DomainAndCategory; ## no critic (TidyCode)

use strict;
use warnings;
use Carp qw(confess cluck);
use Locale::Utils::PlaceholderNamed;
use Moo::Role;
use namespace::autoclean;

our $VERSION = '1.014';

with qw(
    Locale::TextDomain::OO::Plugin::Expand::Gettext::Loc
);

requires qw(
    category
    domain
);

has _shadow_domains => (
    is      => 'rw',
    default => sub { [] },
);

has _shadow_categories => (
    is      => 'rw',
    default => sub { [] },
);

sub loc_begin_d {
    my ($self, $domain) = @_;

    defined $domain
        or confess 'Domain is not defined';
    push
        @{ $self->_shadow_domains },
        $self->domain;
    $self->domain($domain);

    return $self;
}

sub loc_begin_c {
    my ($self, $category) = @_;

    defined $category
        or confess 'Category is not defined';
    push
        @{ $self->_shadow_categories },
        $self->category;
    $self->category($category);

    return $self;
}

sub loc_begin_dc {
    my ($self, $domain, $category) = @_;

    $self->loc_begin_d($domain);
    $self->loc_begin_c($category);

    return $self;
}

sub loc_end_d {
    my $self = shift;

    if ( ! @{ $self->_shadow_domains } ) {
        cluck 'Tried to get the domain from stack but no domain is not stored';
        return $self;
    }
    $self->domain( pop @{ $self->_shadow_domains } );

    return $self;
}

sub loc_end_c {
    my $self = shift;

    if ( ! @{ $self->_shadow_categories } ) {
        cluck 'Tried to get the category from stack but no category is stored',
        return $self;
    }
    $self->category( pop @{ $self->_shadow_categories } );

    return $self;
}

sub loc_end_dc {
    my $self = shift;

    $self->loc_end_d;
    $self->loc_end_c;

    return $self;
}

sub loc_dx {
    my ( $self, $domain, @more ) = @_;

    $self->loc_begin_d($domain);
    my $translation = $self->loc_x(@more);
    $self->loc_end_d;

    return $translation;
}

sub loc_cx {
    my ($self, @more) = @_;

    $self->loc_begin_c( splice @more, 1, 1 );
    my $translation = $self->loc_x(@more);
    $self->loc_end_c;

    return $translation;
}

sub loc_dcx {
    my ( $self, $domain, @more ) = @_;

    $self->loc_begin_d($domain);
    my $translation = $self->loc_cx(@more);
    $self->loc_end_d;

    return $translation;
}

sub loc_dnx {
    my ( $self, $domain, @more ) = @_;

    $self->loc_begin_d($domain);
    my $translation = $self->loc_nx(@more);
    $self->loc_end_d;

    return $translation;
}

sub loc_cnx {
    my ( $self, @more ) = @_;

    $self->loc_begin_c( splice @more, 3, 1 ); ## no critic (MagicNumbers)
    my $translation = $self->loc_nx(@more);
    $self->loc_end_c;

    return $translation;
}

sub loc_dcnx {
    my ( $self, $domain, @more ) = @_;

    $self->loc_begin_d($domain);
    my $translation = $self->loc_cnx(@more);
    $self->loc_end_d;

    return $translation;
}

sub loc_dpx {
    my ( $self, $domain, @more ) = @_;

    $self->loc_begin_d($domain);
    my $translation = $self->loc_px(@more);
    $self->loc_end_d;

    return $translation;
}

sub loc_cpx {
    my ( $self, @more ) = @_;

    $self->loc_begin_c( splice @more, 2, 1 );
    my $translation = $self->loc_px(@more);
    $self->loc_end_c;

    return $translation;
}

sub loc_dcpx {
    my ( $self, $domain, @more ) = @_;

    $self->loc_begin_d($domain);
    my $translation = $self->loc_cpx(@more);
    $self->loc_end_d;

    return $translation;
}

sub loc_dnpx {
    my ( $self, $domain, @more ) = @_;

    $self->loc_begin_d($domain);
    my $translation = $self->loc_npx(@more);
    $self->loc_end_d;

    return $translation;
}

sub loc_cnpx {
    my ($self, @more) = @_;

    $self->loc_begin_c( splice @more, 4, 1 ); ## no critic (MagicNumbers)
    my $translation = $self->loc_npx(@more);
    $self->loc_end_c;

    return $translation;
}

sub loc_dcnpx {
    my ( $self, $domain, @more ) = @_;

    $self->loc_begin_d($domain);
    my $translation = $self->loc_cnpx(@more);
    $self->loc_end_d;

    return $translation;
}

BEGIN {
    no warnings qw(redefine); ## no critic (NoWarnings)

    # Dummy methods for string marking.
    my $dummy = sub {
        my (undef, @more) = @_;
        return wantarray ? @more : $more[0];
    };

    *loc_d   = \&loc_dx;
    *loc_dn  = \&loc_dnx;
    *loc_dp  = \&loc_dpx;
    *loc_dnp = \&loc_dnpx;

    *loc_c   = \&loc_cx;
    *loc_cn  = \&loc_cnx;
    *loc_cp  = \&loc_cpx;
    *loc_cnp = \&loc_cnpx;

    *loc_dc   = \&loc_dcx;
    *loc_dcn  = \&loc_dcnx;
    *loc_dcp  = \&loc_dcpx;
    *loc_dcnp = \&loc_dcnpx;

    *Nloc_d   = $dummy;
    *Nloc_dn  = $dummy;
    *Nloc_dp  = $dummy;
    *Nloc_dnp = $dummy;

    *Nloc_dx   = $dummy;
    *Nloc_dnx  = $dummy;
    *Nloc_dpx  = $dummy;
    *Nloc_dnpx = $dummy;

    *Nloc_c   = $dummy;
    *Nloc_cn  = $dummy;
    *Nloc_cp  = $dummy;
    *Nloc_cnp = $dummy;

    *Nloc_cx   = $dummy;
    *Nloc_cnx  = $dummy;
    *Nloc_cpx  = $dummy;
    *Nloc_cnpx = $dummy;

    *Nloc_dc   = $dummy;
    *Nloc_dcn  = $dummy;
    *Nloc_dcp  = $dummy;
    *Nloc_dcnp = $dummy;

    *Nloc_dcx   = $dummy;
    *Nloc_dcnx  = $dummy;
    *Nloc_dcpx  = $dummy;
    *Nloc_dcnpx = $dummy;
}

1;

__END__

=head1 NAME

Locale::TextDomain::OO::Plugin::Expand::Gettext::Loc::DomainAndCategory - Methods for dynamic domain and/or category, prefixed with loc_

$Id: DomainAndCategory.pm 545 2014-10-30 13:23:00Z steffenw $

$HeadURL: svn+ssh://steffenw@svn.code.sf.net/p/perl-gettext-oo/code/module/trunk/lib/Locale/TextDomain/OO/Plugin/Expand/Gettext/Loc/DomainAndCategory.pm $

=head1 VERSION

1.014

=head1 DESCRIPTION

This methods swiching the domain and/or category during translation process.

I am not sure if that is the best way to do.
Maybe that will change in future.

=head1 SYNOPSIS

    my $loc = Locale::Text::TextDomain::OO->new(
        plugins => [ qw (
            Expand::Gettext::Loc::DomainAndCategory
            ...
        )],
        ...
    );

=head1 SUBROUTINES/METHODS

=head2 Switch methods

=head3 methods loc_begin_d, loc_end_d

Switch the domain.

    $loc->loc_begin_d($domain);

All translations using the lexicon of that domain.

    $loc->loc_end_d;

All translations using the lexicon before call of loc_begin_d.

=head3 methods loc_begin_c, loc_end_c

Switch the category.

    $loc->loc_begin_c($category);

All translations using the lexicon of that category.

    $loc->loc_end_c;

All translations using the lexicon before call of loc_begin_c.

=head3 methods loc_begin_dc, loc_end_dc

Switch the domain and category.

    $loc->loc_begin_dc($domain, $category);

All translations using the lexicon of that domain and category.

    $loc->loc_end_dc;

All translations using the lexicon before call of loc_begin_dc.

=head2 Translation methods

=head3 methods loc_d, loc_dn, loc_dp, loc_dnp, loc_dx, loc_dnx, loc_dpx, loc_dnpx

Switch to that domain, translate and switch back.

    $translation = $loc->loc_dx('domain', 'msgid', key => value );

Other methods are similar extended.
The domain is the 1st parameter.

=head3 methods loc_c, loc_cn, loc_cp, loc_cnp, loc_cx, loc_cnx, loc_cpx, loc_cnpx

Switch to that category, translate and switch back.

    $translation = $loc->loc_cx('msgid', 'category', key => value );

Other methods are similar extended.
The category is the last parameter
but before the placeholder replacement hash/hash_ref.

=head3 methods loc_dc, loc_dcn, loc_dcp, loc_dcnp, loc_dcx, loc_dcnx, loc_dcpx, loc_dcnpx

Switch to that domain and category, translate and switch back both.

    $translation = $loc->loc_dcx('domain', 'msgid', 'category', key => value );

Other methods are similar extended.
The domain is the 1st parameter.
The category is the last parameter
but before the placeholder replacement hash/hash_ref.

=head3 methods Nloc_d, Nloc_dn, Nloc_dp, Nloc_dnp, Nloc_dx, Nloc_dnx, Nloc_dpx, Nloc_dnpx

none translating methods with domain

=head3 methods Nloc_c, Nloc_cn, Nloc_cp, Nloc_cnp, Nloc_cx, Nloc_cnx, Nloc_cpx, Nloc_cnpx

none translating methods with category

=head3 methods Nloc_dc, Nloc_dcn, Nloc_dcp, Nloc_dcnp, Nloc_dcx, Nloc_dcnx, Nloc_dcpx, Nloc_dcnpx

none translating methods with domain and category

=head1 EXAMPLE

Inside of this distribution is a directory named example.
Run this *.pl files.

=head1 DIAGNOSTICS

confess

cluck

=head1 CONFIGURATION AND ENVIRONMENT

none

=head1 DEPENDENCIES

L<Carp|Carp>

L<Locale::Utils::PlaceholderNamed|Locale::Utils::PlaceholderNamed>

L<Moo::Role|Moo::Role>

L<namespace::autoclean|namespace::autoclean>

L<Locale::TextDomain::OO::Plugin::Expand::Gettext::Loc|Locale::TextDomain::OO::Plugin::Expand::Gettext::Loc>

=head1 INCOMPATIBILITIES

not known

=head1 BUGS AND LIMITATIONS

none

=head1 SEE ALSO

L<Locale::TextDoamin::OO|Locale::TextDoamin::OO>

=head1 AUTHOR

Steffen Winkler

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2013,
Steffen Winkler
C<< <steffenw at cpan.org> >>.
All rights reserved.

This module is free software;
you can redistribute it and/or modify it
under the same terms as Perl itself.
