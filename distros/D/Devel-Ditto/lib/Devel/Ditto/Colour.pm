package Devel::Ditto::Colour;

use strict;
use warnings;

use Carp;

use base qw( Devel::Ditto );

=head1 NAME

Devel::Ditto::Colour - Colour version of Devel::Ditto

=head1 VERSION

This document describes Devel::Ditto version 0.06

=head1 SYNOPSIS

  $ perl -MDevel::Ditto::Colour myprog.pl
  [main, t/myprog.pl, 9] This is regular text
  [main, t/myprog.pl, 10] This is a warning
  [MyPrinter, t/lib/MyPrinter.pm, 7] Hello, World
  [MyPrinter, t/lib/MyPrinter.pm, 8] Whappen?

=cut

our $VERSION = '0.06';

sub import {
  my $class = shift;
  eval "use Term::ANSIColor";
  croak "Need Term::ANSIColor to use ", __PACKAGE__ if $@;
  $class->SUPER::import( @_ );
}

sub _logbit {
  my $self = shift;
  my $lb   = $self->SUPER::_logbit;
  return Term::ANSIColor::colored(
    [ $self->{is_err} ? 'red' : 'green' ], $lb );
}

1;
__END__

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-devel-Ditto@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Andy Armstrong  C<< <andy@hexten.net> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2009, Andy Armstrong C<< <andy@hexten.net> >>.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

