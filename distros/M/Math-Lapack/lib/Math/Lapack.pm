# ABSTRACT: Perl interface to LAPACK
use strict;
use warnings;
package Math::Lapack;

use parent 'DynaLoader';

bootstrap Math::Lapack;
sub dl_load_flags { 1 }




sub seed_rng {
  my $val = shift;
  $val = shift if $val eq __PACKAGE__;
  _srand($val);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Math::Lapack - Perl interface to LAPACK

=head1 VERSION

version 0.001

=for Pod::Coverage seed_rng

=head2 DESCRIPTION

This module exists, for now, as a wrapper for the C/XS code, for interaction with Lapack C libraries.
Please refer to L<Math::Lapack::Matrix> for usage details.

=head1 AUTHOR

Rui Meira

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018-2019 by Rui Meira.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
