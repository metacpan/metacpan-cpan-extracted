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

package Language::Befunge::lib::BASE;
# ABSTRACT: Non-standard math bases extension
$Language::Befunge::lib::BASE::VERSION = '5.000';
use Math::BaseCalc;

sub new { return bless {}, shift; }

my @digits = ( 0 .. 9, 'a'..'z' );

# -- outputs

#
# B( $n )
#
# Output top of stack in binary.
#
sub B { 
	my ($self, $lbi) = @_;
	printf "%b", $lbi->get_curip->spop;
}


#
# H( $n )
#
# Output top of stack in binary.
#
sub H {
	my ($self, $lbi) = @_;
	printf "%x", $lbi->get_curip->spop;
}


#
# N( $n, $b )
#
# Output $n in base $b.
#
sub N {
	my ($self, $lbi) = @_;
	my $ip = $lbi->get_curip;
	my $b = $ip->spop;
	my $n = $ip->spop;
	if ( $b == 0 || $b == 1 || $b > scalar(@digits) ) {
		# bases 0 and 1 are not valid.
		# bases greater than 36 require too much chars.
		$ip->dir_reverse;
		return;
	}
	my $bc = Math::BaseCalc->new(digits=> [ @digits[0..$b-1] ]);
	print $bc->to_base( $n );
}

#
# O( $n )
#
# Output top of stack in octal.
#
sub O {
	my ($self, $lbi) = @_;
	printf "%o", $lbi->get_curip->spop;
}


# -- input

#
# $n = I( $b )
#
# Input value in specified base, and push it on the stack.
#
sub I {
    my ($self, $lbi) = @_;
    my $ip = $lbi->get_curip;
    my $in = $lbi->get_input;
    return $ip->dir_reverse unless defined $in;
    my $b = $ip->spop;
    if ( $b == 0 || $b == 1 || $b > scalar(@digits) ) {
		# bases 0 and 1 are not valid.
		# bases greater than 36 require too much chars.
		$ip->dir_reflect;
		return;
	}
	my $bc = Math::BaseCalc->new(digits=> [ @digits[0..$b-1] ]);
    
    $ip->spush( $bc->to_base( $in ) );
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Language::Befunge::lib::BASE - Non-standard math bases extension

=head1 VERSION

version 5.000

=head1 DESCRIPTION

The BASE fingerprint (0x42415345) allows numbers to be output-ed in whatever
base you want. Note that bases are limited to base 36 maximum for practical
reasons (missing chars to represent high numbers)

=head1 FUNCTIONS

=head2 new

Create a new BASE instance.

=head2 Output

=over 4

=item B( $n )

Output top of stack in binary.

=item H( $n )

Output top of stack in hexa.

=item N( $n, $b )

Output C<$n> in base C<$b>.

=item O( $n )

Output top of stack in octal.

=back

=head2 Input

=over 4

=item $n = I( $b )

Input value in specified base, and push it on the stack.

=back

=head1 SEE ALSO

L<http://www.rcfunge98.com/rcsfingers.html#BASE>.

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2003 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
