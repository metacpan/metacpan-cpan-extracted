#
# This file is part of Language-Befunge
#
# This software is copyright (c) 2003 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict;
use warnings;

package Language::Befunge::lib::REFC;
# ABSTRACT: Referenced cells extension
$Language::Befunge::lib::REFC::VERSION = '5.000';
use Language::Befunge::Vector;

sub new { return bless {}, shift; }

my @vectors;


#
# $id = R( $x, $y )
#
# 'Reference' pops a vector off the stack, and pushes a scalar value back onto
# the stack, unique within an internal list of references, which refers to that
# vector.
#
sub R { 
	my ($self, $lbi) = @_;
	my $ip = $lbi->get_curip;
	my $v  = $ip->spop_vec;
	push @vectors, $v;
	$ip->spush( $#vectors );
}


#
# ($x, $y) = D( $id )
#
# 'Dereference' pops a scalar value off the stack, and pushes the vector back
# onto the stack which corresponds to that unique reference value.
#
sub D {
	my ($self, $lbi) = @_;
	my $ip = $lbi->get_curip;
	my $id = $ip->spop;
	my $v = $vectors[$id];
	$ip->spush( $v->get_component(0), $v->get_component(1) );
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Language::Befunge::lib::REFC - Referenced cells extension

=head1 VERSION

version 5.000

=head1 DESCRIPTION

The REFC fingerprint (0x52454643) allows vectors to be encoded into and
decoded from single scalar cell values.

Note that the internal list of references is considered shared among all
IP's. 

=head1 FUNCTIONS

=head2 new

Create a new REFC instance.

=head2 De/Referencing

=over 4

=item $id = R( $x, $y )

C<Reference> pops a vector off the stack, and pushes a scalar value back onto
the stack, unique within an internal list of references, which refers to that
vector.

=item ($x, $y) = D( $id )

C<Dereference> pops a scalar value off the stack, and pushes the vector back
onto the stack which corresponds to that unique reference value.

=back

=head1 SEE ALSO

L<http://catseye.tc/projects/funge98/library/REFC.html>.

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2003 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
