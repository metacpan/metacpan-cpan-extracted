=head1 NAME

Math::RandomOrg - Retrieve random numbers and data from random.org.

=head1 SYNOPSIS

  use Math::RandomOrg qw(randnum randbyte);
  my $number = randnum(0, 10);
  my $octet = randbyte(1);

=head1 DESCRIPTION

Math::RandomOrg provides functions for retrieving random data from the random.org server.
Data may be retrieved in an integer or byte-stream format using the C<randnum> and C<randbyte> functions respectively.

=head1 REQUIRES

=over 4

=item Carp

=item Exporter

=item Math::BigInt

=item LWP::Simple

=back

=head1 EXPORT

None by default. You may request the following symbols be exported:

=over 4

=item * randnum

=item * randbyte

=back

=cut

package Math::RandomOrg;

use strict;
use warnings;

our ($VERSION, @ISA, @EXPORT, @EXPORT_OK);

require Exporter;
@ISA = qw(Exporter);

@EXPORT_OK = qw( checkbuf randnum randbyte randseq );
@EXPORT = qw();
$VERSION = '0.04';

use Carp;
use Math::BigInt;
use LWP::Simple ();

my $RAND_MIN	= new Math::BigInt "-1000000000";	# random.org fixed min
my $RAND_MAX	= new Math::BigInt "1000000000";	# random.org fixed max
my $NUM_BUF	= 256;									# at least, request this number of random integers in each request to random.org

=head1 FUNCTIONS

=over 4

=cut

{
	my @randnums;

=item C<checkbuf()>

This routine takes no parameters and simply returns a single value (e.g., 
C<28%>) telling you how full the buffer is. At 100%, the buffer is full 
and you are free to hit it with automated clients. At 0%, the buffer is 
empty and requests will hang. When less than 100%, the buffer is being 
filled continually, but doing so takes time. I advise people with 
automated clients to check the buffer level every once in a while and only 
issue requests when the buffer level is 20% or higher.

=cut

	sub checkbuf {
		my $url		= "http://www.random.org/cgi-bin/checkbuf";
		my $data	= LWP::Simple::get( $url );
		if (defined($data)) {
			$data =~ s/\%//;
			return $data;
		} else {
			carp "HTTP GET failed for $url";
			return;
		}
	}

=item C<randnum ( $min, $max )>

Return an integer (specifically a Math::BigInt object) between the bounds [ $min, $max ] (inclusive).

By default, $max and $min are positive and negative 1e9, respectively. These default
values represent random.org's current extrema for the bounds of the randnum function.
Therefore, $min and $max may not exceed the default values.

=cut
	sub randnum (;$$) {
		use integer;
		my $min	= new Math::BigInt (defined($_[0]) ? $_[0] : $RAND_MIN);
		my $max	= new Math::BigInt (defined($_[1]) ? $_[1] : $RAND_MAX);
		if ($min < $RAND_MIN or $max > $RAND_MAX) {
			carp "The $min and $max arguments to the randnum() function may not exceed the bounds ($RAND_MIN, $RAND_MAX)!";
			return undef;
		}
		if ($#randnums == -1) {
			my $url		= "http://www.random.org/cgi-bin/randnum?num=${NUM_BUF}&min=${RAND_MIN}&max=${RAND_MAX}&col=1";
			my $data	= LWP::Simple::get( $url );
			if (defined($data)) {
				@randnums	= map { new Math::BigInt $_ } (split(/\n/, $data));
			} else {
				carp "HTTP GET failed for $url";
				return undef;
			}
		}
		my $num	= shift(@randnums);
		
		$num	-= $RAND_MIN;
		$num	*= (1 + $max - $min);
		$num	/= ($RAND_MAX - $RAND_MIN);
		$num	+= $min;
		
		return $num;
	}

	my $randbytes	= '';

=item C<randbyte ( $length )>

Returns an octet-string of specified length (defaults to one byte), which contains random bytes.

$length may not exceed 16,384, as this is the maximum number of bytes retrievable from the
random.org server in one request, and making multiple requests for an unbounded amount of
data would unfairly tax the random.org server. If you need large amounts of random data,
you may wish to try the Math::TrulyRandom module.

=cut
	sub randbyte (;$) {
		my $length	= +(shift || 1);
		if ($length > 16_384) {
			carp "randbyte() should not be used to generate random data larger than 16,384 bytes (lest we swamp random.org's entropy source).";
			return '';
		} elsif (length($randbytes) < $length) {
			my $nbytes	= ($length > 512) ? $length : 512;
			my $url		= "http://www.random.org/cgi-bin/randbyte?nbytes=${nbytes}&format=f";
			my $data	= LWP::Simple::get( $url );
			if (defined($data)) {
				$randbytes	.= $data;
			} else {
				carp "HTTP GET failed for $url";
				return undef;
			}
		}
		return substr($randbytes, 0, $length, '');
	}
}

=item C<randseq ( $min, $max )>

The randseq script returns a randomized sequence of numbers. This corresponds to dropping a number of lottery tickets into a hat and drawing them out in random order. Hence, each number in a randomized sequence occurs exactly once.

Example: C<randseq(1, 10)> will return the numbers between 1 and 10 (both inclusive) in a random order.

=cut

	sub randseq (;$$) {
		my ($min, $max) = @_;
		return if ( (! defined $min) || (! defined $max) || ($min !~ /^\-?\d+$/) || ($max !~ /^\-?\d+$/) );
		if ($max < $min) {
			carp "MAX must be greater than MIN.";
			return;
		}
		if ($max - $min > 10000) {
			carp "random.org restricts the size of sequences to <= 10,000.";
			return;
		}
		my @sequence = ();
		my $url		= "http://www.random.org/cgi-bin/randseq?min=$min&max=$max";
		my $data	= LWP::Simple::get( $url );
		if (defined($data)) {
			@sequence = map { new Math::BigInt $_ } (split(/\n/, $data));
		} else {
			carp "HTTP GET failed for $url";
			return undef;
		}
		
		return wantarray ? @sequence : \@sequence;
	}

1;
__END__

=back

=head1 BUGS

None known.

=head1 SEE ALSO

=over 4

=item * L<Math::TrulyRandom>

=item * L<rand>

=back

=head1 COPYRIGHT

Copyright (c) 2001-2006 Gregory Todd Williams. All rights reserved. This
program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

Gregory Todd Williams  C<< <gwilliams@cpan.org> >>

=cut
