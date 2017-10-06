package Locale::TextDomain::OO::Role::DomainAndCategory; ## no critic (TidyCode)

use strict;
use warnings;
use Carp qw(confess cluck);
use Locale::TextDomain::OO::Translator;
use Moo::Role;

our $VERSION = '1.030';

requires qw(
    category
    domain
);

our ( @domains, @categories ); ## no critic (PackageVars)

sub callback_scope {
    my ( $self, $callback ) = @_;

    local @domains    = @domains;    ## no critic (LocalVars)
    local @categories = @categories; ## no critic (LocalVars)
    my $domain   = $self->domain;
    my $category = $self->category;
    my $translation = $callback->();
    $self->domain($domain);
    $self->category($category);

    return $translation;
}

sub begin_d {
    my ($self, $domain) = @_;

    defined $domain
        or confess 'Domain is not defined';
    push
        @domains,
        $self->domain;
    $self->domain($domain);

    return $self;
}

sub begin_c {
    my ($self, $category) = @_;

    defined $category
        or confess 'Category is not defined';
    push
        @categories,
        $self->category;
    $self->category($category);

    return $self;
}

sub begin_dc {
    my ($self, $domain, $category) = @_;

    $self->begin_d($domain);
    $self->begin_c($category);

    return $self;
}

sub end_d {
    my $self = shift;

    if ( ! @domains ) {
        cluck 'Tried to get the domain from stack but no domain is not stored';
        return $self;
    }
    $self->domain( pop @domains );

    return $self;
}

sub end_c {
    my $self = shift;

    if ( ! @categories ) {
        cluck 'Tried to get the category from stack but no category is stored',
        return $self;
    }
    $self->category( pop @categories );

    return $self;
}

sub end_dc {
    my $self = shift;

    $self->end_d;
    $self->end_c;

    return $self;
}

1;

__END__

=head1 NAME

Locale::TextDomain::OO::Role::DomainAndCategory - Provides domain and category switch methods

$Id: DomainAndCategory.pm 689 2017-08-29 21:37:38Z steffenw $

$HeadURL: svn+ssh://steffenw@svn.code.sf.net/p/perl-gettext-oo/code/module/trunk/lib/Locale/TextDomain/OO/Role/DomainAndCategory.pm $

=head1 VERSION

1.030

=head1 DESCRIPTION

This module provides domain and category switch methods and the local scope for
for L<Locale::TextDomain:OO|Locale::TextDomain:OO>.

=head1 SYNOPSIS

see SUBROUTINES/METHODS

=head1 SUBROUTINES/METHODS

=head2 method callback_scope

    $loc->callback_scope(
        sub {
            # switch domain and/or category
            $loc->begin_...(...);
            return $loc->... # translate
        },
    );
}

=head2 methods begin_d, end_d

Switch the domain.

    $loc->begin_d($domain);

All translations using the lexicon of that domain.

    $loc->end_d;

All translations using the lexicon before call of begin_d.

=head2 methods begin_c, end_c

Switch the category.

    $loc->begin_c($category);

All translations using the lexicon of that category.

    $loc->end_c;

All translations using the lexicon before call of begin_c.

=head2 methods begin_dc, end_dc

Switch the domain and category.

    $loc->begin_dc($domain, $category);

All translations using the lexicon of that domain and category.

    $loc->end_dc;

All translations using the lexicon before call of begin_dc.

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

L<Locale::TextDomain::OO::Translator|Locale::TextDomain::OO::Translator>

L<Moo::Role|Moo::Role>

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
