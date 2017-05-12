package Encode::Float;
use strict;

BEGIN
{
	use Exporter ();
	use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
	$VERSION     = '0.11';
	@ISA         = qw(Exporter);
	@EXPORT      = qw();
	@EXPORT_OK   = qw();
	%EXPORT_TAGS = ();
}

#01234567890123456789012345678901234567890123
#Encode/decode float as a string for sorting.

=head1 NAME

C<Encode::Float> - Encode/decode float as a string for sorting.

=head1 SYNOPSIS

  use Encode::Float;
  my $encoder = Encode::Float->new();
  my @list;
  for (my $i = 0 ; $i < 10 ; $i++)
  {
    my $float = (.5 - rand) * 10**int(10 - 20 * rand);
    $float = 0 if $i == 0;
    my $encoded = $encoder->encode($float);
    my $decoded = $encoder->decode($encoded);
    my $error   = $encoder->getRelativeDifference($float, $decoded);
    push @list, [ $encoded, $float, $decoded, $error ];
  }
  @list = sort { $a->[0] cmp $b->[0] } @list;
  foreach (@list)
  {
    print join(',', @$_) . "\n";
  }

=head1 DESCRIPTION

C<Encode::Float> encodes and decodes floating point numbers
as fixed length positive decimal integers that preserve their order (less
rounding errors), that is, sorting the encoded integers also sorts the 
floating point numbers.

=head1 CONSTRUCTOR

=head2 C<new>

The method C<new> creates an instance of the C<Encode::Float>
class with the following parameter:

=over

=item C<digitsOfAccuracy>

 digitsOfAccuracy => 16

C<digitsOfAccuracy> is an optional parameter that sets the number of
decimal digits to preserve in the floating point number; the default is 16.

=back

=cut

sub new
{
	my ($Class, %Parameters) = @_;
	my $Self = bless({}, ref($Class) || $Class);

	# set the number of digits used to represent a float.
	$Self->{digitsOfAccuracy} = 16;
	$Self->{digitsOfAccuracy} = int abs $Parameters{digitsOfAccuracy} if exists $Parameters{digitsOfAccuracy};
	$Self->{digitsOfAccuracy} = 1 if $Self->{digitsOfAccuracy} < 1;

	# get the maximum integer value.
	my $mantissaMaxStr = '9' x $Self->{digitsOfAccuracy};
	my $mantissaMax    = $mantissaMaxStr + 0;
	if ($mantissaMax ne $mantissaMaxStr)
	{
		die "digitsOfAccuracy =  $Self->{digitsOfAccuracy} is too large.\n";
	}
	$Self->{mantissaMax}    = $mantissaMax;
	$Self->{floatFormat}    = '%+' . '.' . ($Self->{digitsOfAccuracy} - 1) . 'E';
	$Self->{exponentSize}   = 3;
	$Self->{exponentFormat} = '%+0' . ($Self->{exponentSize} + 1) . 'd';
	$Self->{exponentMax}    = '9' x $Self->{exponentSize};
	$Self->{mantissaFormat} = '%0' . $Self->{digitsOfAccuracy} . 'd';
	return $Self;
}

=head1 METHODS

=head2 C<encode>

The method C<encode> takes a floating point number as its only parameter
and returns its integer encoding.

=cut

sub encode
{
	my ($Self, $Float) = @_;

	# convert the float to a string.
	my $string = sprintf($Self->{floatFormat}, $Float);

	# get the mantissa of the float.
	my $mantissa = substr($string, 1, 1) . substr($string, 3, $Self->{digitsOfAccuracy} - 1);

	# get the exponent of the float, with its sign.
	my $exponent = sprintf($Self->{exponentFormat}, substr($string, $Self->{digitsOfAccuracy} + 3));

	# encode the sign of the float and the exponent to a single leading digit.
	my $lead;
	if ($Float < 0)
	{

		# the float is negative, so take the complement of the mantissa.
		$mantissa = sprintf($Self->{mantissaFormat}, $Self->{mantissaMax} - $mantissa);
		if (substr($exponent, 0, 1) eq '-')
		{
			$lead = 2;
		}
		else
		{
			$lead = 1;

			# negative float but positive exponent, so take the complement of the exponent.
			$exponent = sprintf($Self->{exponentFormat}, $Self->{exponentMax} - $exponent);
		}
	}
	else
	{
		if (substr($exponent, 0, 1) eq '-')
		{
			$lead = 3;

			# positive float but negative exponent, so take the complement of the exponent.
			$exponent = sprintf($Self->{exponentFormat}, $Self->{exponentMax} + $exponent);
		}
		else
		{
			$lead = 4;
		}
	}

	# zero is a special case.
	$lead = 3 if $Float == 0;

	# encode the float as a long integer that preserves sort order.
	return $lead . substr($exponent, 1) . $mantissa;
}

=head2 C<decode>

The method C<decode> takes an encoded floating point number (a positive
integer) and returns its floating point number.

=cut

sub decode
{
	my ($Self, $EncodedFloat) = @_;

	# holds the sign of the float.
	my $sign;

	# get the leading digit that encodes the sign of the float and exponent.
	my $lead = substr($EncodedFloat, 0, 1);

	# get the exponent of the float.
	my $exponent = substr($EncodedFloat, 1, $Self->{exponentSize});

	# get the mantissa of the float.
	my $mantissa = substr($EncodedFloat, $Self->{exponentSize} + 1);

	# adjust the exponent and sign via the leading digit.
	if ($lead == 1)
	{
		$sign     = -1;
		$mantissa = $Self->{mantissaMax} - $mantissa;
		$exponent = $Self->{exponentMax} - $exponent;
	}
	elsif ($lead == 2)
	{
		$sign     = -1;
		$mantissa = $Self->{mantissaMax} - $mantissa;
		$exponent = -$exponent;
	}
	elsif ($lead == 3)
	{
		$sign = 1;
		$exponent -= $Self->{exponentMax};
	}
	else
	{
		$sign = 1;
	}

	# return the float.
	$mantissa =~ s/^0+//;
	return 0 unless length $mantissa;
	my $decimal = substr($mantissa, 0, 1) . '.' . substr($mantissa, 1);
	return $sign * $decimal * 10**$exponent;
}

=head2 C<getRelativeDifference>

The method C<getRelativeDifference (floatA, floatB)> computes the relative
difference between the floating point numbers C<floatA> and C<floatB>, which
is C<abs(floatA - floatB)/max(abs(floatA), abs(floatB))> or zero if both 
numbers are zero.

=cut

sub getRelativeDifference
{
	my ($Self, $FloatA, $FloatB) = @_;
	my $absMax    = abs $FloatA;
	my $absFloatB = abs $FloatB;
	$absMax = $absFloatB if $absFloatB > $absMax;
	return 0 unless $absMax;
	return abs($FloatA - $FloatB) / $absMax;
}

=head1 INSTALLATION

Use L<CPAN> to install the module and all its prerequisites:

  perl -MCPAN -e shell
  >install Encode::Float

=head1 BUGS

Please email bugs reports or feature requests to C<bug-encode-float@rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Encode-Float>.  The author
will be notified and you can be automatically notified of progress on the bug fix or feature request.

=head1 AUTHOR

 Jeff Kubina<jeff.kubina@gmail.com>

=head1 COPYRIGHT

Copyright (c) 2013 Jeff Kubina. All rights reserved.
This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 KEYWORDS

decoding, double, encoding, float 

=head1 SEE ALSO

L<CPAN>, L<Sort::External>

=cut

1;

# The preceding line will help the module return a true value
