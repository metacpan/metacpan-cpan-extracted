package Math::Random::TT800;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require DynaLoader;

@ISA = qw(Exporter DynaLoader);

@EXPORT = qw();
@EXPORT_OK = qw();

$VERSION = '1.01';

bootstrap Math::Random::TT800 $VERSION;

1;

__END__


=head1 NAME

Math::Random::TT800 - Matsumoto's TT800 Pseudorandom number generator

=head1 DESCRIPTION

This perl extension module implements M. Matsumoto's twisted generalized
shift register generator called TT800 as described in his article
published in ACM Transactions on Modelling and Computer Simulation, 
Vol. 4, No. 3, 1994, pages 254-266. 

=head1 SYNOPSIS

	use Math::Random::TT800;

	my $tt = new Math::Random::TT800;

	$value = $tt->next();

	$ivalue = $tt->next_int();
	

=head1 FUNCTIONS

=over 4

=item new

        my $tt = new Math::Random::TT800;
        my $tt = new Math::Random::TT800 @seeds;

Create a new TT800 object. Providing seeds is optional.
A TT800 takes 25 integers as seed which must not be all zero.
If less than 25 integers are supplied, the rest are taken from the
default seed.


=item next

	$value = $tt->next();

next returns the next pseudorandom number from the TT800 object as
a floating point value in the range [0,1).

=item next_int

	$ivalue = $tt->next_int();

next_int returns a integer value filled with 32 random bits.

=back

=head1 COPYRIGHT

This implementation is based on the C code by M. Matsumoto
<matumoto@math.keio.ac.jp> available from 
ftp://random.mat.sbg.ac.at/pub/data/tt800.c.

Converted to a perl extension module and enhancements to 
support multiple streams of pseudorandom numbers 
by Otmar Lendl <lendl@cosy.sbg.ac.at>.

Copyright (c) 1997 by Otmar Lendl (Perl and XS code). All rights
reserved. This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
