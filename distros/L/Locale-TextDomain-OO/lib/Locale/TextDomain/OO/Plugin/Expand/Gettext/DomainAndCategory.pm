package Locale::TextDomain::OO::Plugin::Expand::Gettext::DomainAndCategory; ## no critic (TidyCode)

use strict;
use warnings;
use Carp qw(confess cluck);
use Locale::Utils::PlaceholderNamed;
use Moo::Role;
use namespace::autoclean;

our $VERSION = '1.014';

with qw(
    Locale::TextDomain::OO::Plugin::Expand::Gettext
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

sub __begin_d {
    my ($self, $domain) = @_;

    defined $domain
        or confess 'Domain is not defined';
    push
        @{ $self->_shadow_domains },
        $self->domain;
    $self->domain($domain);

    return $self;
}

sub __begin_c {
    my ($self, $category) = @_;

    defined $category
        or confess 'Category is not defined';
    push
        @{ $self->_shadow_categories },
        $self->category;
    $self->category($category);

    return $self;
}

sub __begin_dc { ## no critic (UnusedPrivateSubroutines)
    my ($self, $domain, $category) = @_;

    $self->__begin_d($domain);
    $self->__begin_c($category);

    return $self;
}

sub __end_d {
    my $self = shift;

    if ( ! @{ $self->_shadow_domains } ) {
        cluck 'Tried to get the domain from stack but no domain is not stored';
        return $self;
    }
    $self->domain( pop @{ $self->_shadow_domains } );

    return $self;
}

sub __end_c {
    my $self = shift;

    if ( ! @{ $self->_shadow_categories } ) {
        cluck 'Tried to get the category from stack but no category is stored',
        return $self;
    }
    $self->category( pop @{ $self->_shadow_categories } );

    return $self;
}

sub __end_dc { ## no critic (UnusedPrivateSubroutines)
    my $self = shift;

    $self->__end_d;
    $self->__end_c;

    return $self;
}

sub __dx {
    my ( $self, $domain, @more ) = @_;

    $self->__begin_d($domain);
    my $translation = $self->__x(@more);
    $self->__end_d;

    return $translation;
}

sub __cx {
    my ($self, @more) = @_;

    $self->__begin_c( splice @more, 1, 1 );
    my $translation = $self->__x(@more);
    $self->__end_c;

    return $translation;
}

sub __dcx {
    my ( $self, $domain, @more ) = @_;

    $self->__begin_d($domain);
    my $translation = $self->__cx(@more);
    $self->__end_d;

    return $translation;
}

sub __dnx {
    my ( $self, $domain, @more ) = @_;

    $self->__begin_d($domain);
    my $translation = $self->__nx(@more);
    $self->__end_d;

    return $translation;
}

sub __cnx {
    my ( $self, @more ) = @_;

    $self->__begin_c( splice @more, 3, 1 ); ## no critic (MagicNumbers)
    my $translation = $self->__nx(@more);
    $self->__end_c;

    return $translation;
}

sub __dcnx {
    my ( $self, $domain, @more ) = @_;

    $self->__begin_d($domain);
    my $translation = $self->__cnx(@more);
    $self->__end_d;

    return $translation;
}

sub __dpx {
    my ( $self, $domain, @more ) = @_;

    $self->__begin_d($domain);
    my $translation = $self->__px(@more);
    $self->__end_d;

    return $translation;
}

sub __cpx {
    my ( $self, @more ) = @_;

    $self->__begin_c( splice @more, 2, 1 );
    my $translation = $self->__px(@more);
    $self->__end_c;

    return $translation;
}

sub __dcpx {
    my ( $self, $domain, @more ) = @_;

    $self->__begin_d($domain);
    my $translation = $self->__cpx(@more);
    $self->__end_d;

    return $translation;
}

sub __dnpx {
    my ( $self, $domain, @more ) = @_;

    $self->__begin_d($domain);
    my $translation = $self->__npx(@more);
    $self->__end_d;

    return $translation;
}

sub __cnpx {
    my ($self, @more) = @_;

    $self->__begin_c( splice @more, 4, 1 ); ## no critic (MagicNumbers)
    my $translation = $self->__npx(@more);
    $self->__end_c;

    return $translation;
}

sub __dcnpx {
    my ( $self, $domain, @more ) = @_;

    $self->__begin_d($domain);
    my $translation = $self->__cnpx(@more);
    $self->__end_d;

    return $translation;
}

BEGIN {
    no warnings qw(redefine); ## no critic (NoWarnings)

    # Dummy methods for string marking.
    my $dummy = sub {
        my (undef, @more) = @_;
        return wantarray ? @more : $more[0];
    };

    *__d   = \&__dx;
    *__dn  = \&__dnx;
    *__dp  = \&__dpx;
    *__dnp = \&__dnpx;

    *__c   = \&__cx;
    *__cn  = \&__cnx;
    *__cp  = \&__cpx;
    *__cnp = \&__cnpx;

    *__dc   = \&__dcx;
    *__dcn  = \&__dcnx;
    *__dcp  = \&__dcpx;
    *__dcnp = \&__dcnpx;

    *N__d   = $dummy;
    *N__dn  = $dummy;
    *N__dp  = $dummy;
    *N__dnp = $dummy;

    *N__dx   = $dummy;
    *N__dnx  = $dummy;
    *N__dpx  = $dummy;
    *N__dnpx = $dummy;

    *N__c   = $dummy;
    *N__cn  = $dummy;
    *N__cp  = $dummy;
    *N__cnp = $dummy;

    *N__cx   = $dummy;
    *N__cnx  = $dummy;
    *N__cpx  = $dummy;
    *N__cnpx = $dummy;

    *N__dc   = $dummy;
    *N__dcn  = $dummy;
    *N__dcp  = $dummy;
    *N__dcnp = $dummy;

    *N__dcx   = $dummy;
    *N__dcnx  = $dummy;
    *N__dcpx  = $dummy;
    *N__dcnpx = $dummy;
}

1;

__END__

=head1 NAME

Locale::TextDomain::OO::Plugin::Expand::Gettext::DomainAndCategory - Methods for dynamic domain and/or category, prefixed with __

$Id: DomainAndCategory.pm 543 2014-10-29 08:26:25Z steffenw $

$HeadURL: svn+ssh://steffenw@svn.code.sf.net/p/perl-gettext-oo/code/module/trunk/lib/Locale/TextDomain/OO/Plugin/Expand/Gettext/DomainAndCategory.pm $

=head1 VERSION

1.014

=head1 DESCRIPTION

This methods swiching the domain and/or category during translation process.

I am not sure if that is the best way to do.
Maybe that will change in future.

=head1 SYNOPSIS

    my $loc = Locale::Text::TextDomain::OO->new(
        plugins => [ qw (
            Expand::Gettext::DomainAndCategory
            ...
        )],
        ...
    );

=head1 SUBROUTINES/METHODS

=head2 Switch methods

=head3 methods __begin_d, __end_d

Switch the domain.

    $loc->__begin_d($domain);

All translations using the lexicon of that domain.

    $loc->__end_d;

All translations using the lexicon before call of __begin_d.

=head3 methods __begin_c, __end_c

Switch the category.

    $loc->__begin_c($category);

All translations using the lexicon of that category.

    $loc->__end_c;

All translations using the lexicon before call of __begin_c.

=head3 methods __begin_dc, __end_dc

Switch the domain and category.

    $loc->__begin_dc($domain, $category);

All translations using the lexicon of that domain and category.

    $loc->__end_dc;

All translations using the lexicon before call of __begin_dc.

=head2 Translation methods

=head3 methods __d, __dn, __dp, __dnp, __dx, __dnx, __dpx, __dnpx

Switch to that domain, translate and switch back.

    $translation = $loc->__dx('domain', 'msgid', key => value );

Other methods are similar extended.
The domain is the 1st parameter.

=head3 methods __c, __cn, __cp, __cnp, __cx, __cnx, __cpx, __cnpx

Switch to that category, translate and switch back.

    $translation = $loc->__cx('msgid', 'category', key => value );

Other methods are similar extended.
The category is the last parameter
but before the placeholder replacement hash/hash_ref.

=head3 methods __dc, __dcn, __dcp, __dcnp, __dcx, __dcnx, __dcpx, __dcnpx

Switch to that domain and category, translate and switch back both.

    $translation = $loc->__dcx('domain', 'msgid', 'category', key => value );

Other methods are similar extended.
The domain is the 1st parameter.
The category is the last parameter
but before the placeholder replacement hash/hash_ref.

=head3 methods N__d, N__dn, N__dp, N__dnp, N__dx, N__dnx, N__dpx, N__dnpx

none translating methods with domain

=head3 methods N__c, N__cn, N__cp, N__cnp, N__cx, N__cnx, N__cpx, N__cnpx

none translating methods with category

=head3 methods N__dc, N__dcn, N__dcp, N__dcnp, N__dcx, N__dcnx, N__dcpx, N__dcnpx

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

L<Locale::TextDomain::OO::Plugin::Expand::Gettext|Locale::TextDomain::OO::Plugin::Expand::Gettext>

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
