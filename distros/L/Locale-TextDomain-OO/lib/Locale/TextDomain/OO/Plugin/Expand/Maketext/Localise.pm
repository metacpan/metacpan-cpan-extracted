package Locale::TextDomain::OO::Plugin::Expand::Maketext::Localise; ## no critic (TidyCode)

use strict;
use warnings;
use Moo::Role;
use namespace::autoclean;

our $VERSION = '1.014';

with qw(
    Locale::TextDomain::OO::Plugin::Expand::Maketext
);

{
    no warnings qw(redefine); ## no critic (NoWarnings)
    *localise     = \&Locale::TextDomain::OO::Plugin::Expand::Maketext::maketext;
    *localise_m   = \&Locale::TextDomain::OO::Plugin::Expand::Maketext::maketext;
    *localise_mp  = \&Locale::TextDomain::OO::Plugin::Expand::Maketext::maketext_p;
    *Nlocalise    = \&Locale::TextDomain::OO::Plugin::Expand::Maketext::Nmaketext;
    *Nlocalise_m  = \&Locale::TextDomain::OO::Plugin::Expand::Maketext::Nmaketext;
    *Nlocalise_mp = \&Locale::TextDomain::OO::Plugin::Expand::Maketext::Nmaketext_p;
}

1;

__END__

=head1 NAME

Locale::TextDomain::OO::Plugin::Expand::Maketext::Localise - Alternative maketext methods

$Id: Localise.pm 547 2014-10-31 09:56:41Z steffenw $

$HeadURL: svn+ssh://steffenw@svn.code.sf.net/p/perl-gettext-oo/code/module/trunk/lib/Locale/TextDomain/OO/Plugin/Expand/Maketext/Localise.pm $

=head1 VERSION

1.014

=head1 DESCRIPTION

This module provides alternative maketext methods.

=head1 SYNOPSIS

    my $loc = Locale::TextDomain::OO->new(
        plugins => [ qw(
            Expand::Maketext::Localise
            ...
        ) ],
        ...
    );

=head1 SUBROUTINES/METHODS

=head2 methods localise, localise_m, localise_mp, Nlocalise, Nlocalise_m, Nlocalise_mp

This methods are aliases to method
maketext, maketext, maketext_p, Nmaketext, Nmaketext and Nmaketext_p.

=head1 EXAMPLE

Inside of this distribution is a directory named example.
Run this *.pl files.

=head1 DIAGNOSTICS

nothing

=head1 CONFIGURATION AND ENVIRONMENT

none

=head1 DEPENDENCIES

L<Moo::Role|Moo::Role>

L<namespace::autoclean|namespace::autoclean>

L<Locale::TextDomain::OO::Plugin::Expand::Maketext|Locale::TextDomain::OO::Plugin::Expand::Maketext>

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
