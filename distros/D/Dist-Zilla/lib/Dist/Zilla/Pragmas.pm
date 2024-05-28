package Dist::Zilla::Pragmas 6.032;
# ABSTRACT: the pragmas (boilerplate!) to enable in each Dist::Zilla module

use v5.20.0;
use warnings;
use utf8;

use experimental qw(signatures);

sub import {
  warnings->import;
  utf8->import;

  feature->unimport(':all');
  feature->import(':5.20');
  feature->unimport('switch');

  experimental->import(qw(
    lexical_subs
    postderef
    postderef_qq
    signatures
  ));

  feature->unimport('multidimensional') if $] >= 5.034;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Pragmas - the pragmas (boilerplate!) to enable in each Dist::Zilla module

=head1 VERSION

version 6.032

=head1 PERL VERSION

This module should work on any version of perl still receiving updates from
the Perl 5 Porters.  This means it should work on any version of perl
released in the last two to three years.  (That is, if the most recently
released version is v5.40, then this module should work on both v5.40 and
v5.38.)

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to
lower the minimum required perl.

=head1 AUTHOR

Ricardo SIGNES 😏 <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
