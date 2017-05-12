package Locale::TextDomain::OO::Singleton::Translator; ## no critic (TidyCode)

use strict;
use warnings;
use Moo;
use namespace::autoclean;

our $VERSION = '1.010';

with qw(
    MooX::Singleton
);

extends qw(
    Locale::TextDomain::OO::Translator
);

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Locale::TextDomain::OO::Singleton::Translator - Provides singleton translator

$Id: Translator.pm 496 2014-05-10 18:57:10Z steffenw $

$HeadURL: svn+ssh://steffenw@svn.code.sf.net/p/perl-gettext-oo/code/module/trunk/lib/Locale/TextDomain/OO/Singleton/Translator.pm $

=head1 VERSION

1.010

=head1 DESCRIPTION

This module provides the singleton translator access
for L<Locale::TextDomain:OO|Locale::TextDomain:OO>.

=head1 SYNOPSIS

    use Locale::TextDomain::OO::Singleton::Translator;

    $lexicon_data = Locale::TextDomain::OO::Singleton::Translator->instance;

=head1 SUBROUTINES/METHODS

none

=head1 EXAMPLE

Inside of this distribution is a directory named example.
Run this *.pl files.

=head1 DIAGNOSTICS

none

=head1 CONFIGURATION AND ENVIRONMENT

none

=head1 DEPENDENCIES

L<Moo|Moo>

L<namespace::autoclean|namespace::autoclean>

L<MooX::Singleton|MooX::Singleton>

L<Locale::TextDomain::OO::Singleton::Translator|Locale::TextDomain::OO::Singleton::Translator>

=head1 INCOMPATIBILITIES

not known

=head1 BUGS AND LIMITATIONS

none

=head1 SEE ALSO

L<Locale::TextDoamin::OO|Locale::TextDoamin::OO>

=head1 AUTHOR

Steffen Winkler

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2014,
Steffen Winkler
C<< <steffenw at cpan.org> >>.
All rights reserved.

This module is free software;
you can redistribute it and/or modify it
under the same terms as Perl itself.
