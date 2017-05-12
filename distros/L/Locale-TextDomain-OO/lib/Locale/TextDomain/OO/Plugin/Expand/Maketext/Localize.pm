package Locale::TextDomain::OO::Plugin::Expand::Maketext::Localize; ## no critic (TidyCode)

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
    *localize     = \&Locale::TextDomain::OO::Plugin::Expand::Maketext::maketext;
    *localize_m   = \&Locale::TextDomain::OO::Plugin::Expand::Maketext::maketext;
    *localize_mp  = \&Locale::TextDomain::OO::Plugin::Expand::Maketext::maketext_p;
    *Nlocalize    = \&Locale::TextDomain::OO::Plugin::Expand::Maketext::Nmaketext;
    *Nlocalize_m  = \&Locale::TextDomain::OO::Plugin::Expand::Maketext::Nmaketext;
    *Nlocalize_mp = \&Locale::TextDomain::OO::Plugin::Expand::Maketext::Nmaketext_p;
}

1;

__END__

=head1 NAME

Locale::TextDomain::OO::Plugin::Expand::Maketext::Localize - Alternative maketext methods

$Id: Localize.pm 545 2014-10-30 13:23:00Z steffenw $

$HeadURL: svn+ssh://steffenw@svn.code.sf.net/p/perl-gettext-oo/code/module/trunk/lib/Locale/TextDomain/OO/Plugin/Expand/Maketext/Localize.pm $

=head1 VERSION

1.014

=head1 DESCRIPTION

This module provides alternative maketext methods.

=head1 SYNOPSIS

    my $loc = Locale::TextDomain::OO->new(
        plugins => [ qw(
            Expand::Maketext::Localize
            ...
        ) ],
        ...
    );

=head1 SUBROUTINES/METHODS

=head2 methods localize, localize_m, localize_mp, Nlocalize, Nlocalize_m, Nlocalize_mp

This methods are aliases to method
maketext, maketext, maketext_p,
Nmaketext, Nmaketext and Nmaketext_p.

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
