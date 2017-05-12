package Finance::Performance::Calc;

use 5.006001;
use strict;
use warnings;

require Exporter;

our @ISA = qw (Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw (ROR
				    link_ROR
				    ized_ROR
				    return_percentages
				    trace
				   ) ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw ();
our $VERSION = '1.01';

use Carp;

my %CFG = (
	   return_percentages => 0,
	   trace => 0
	  );

sub return_percentages {
    my $retval = $CFG{'return_percentages'};
    $CFG{'return_percentages'} = $_[0] if scalar(@_);
    return $retval;
}

sub trace {
    my $retval = $CFG{'trace'};
    $CFG{'trace'} = $_[0] if scalar(@_);
    return $retval;
}

sub ROR {
    if(scalar(@_) == 2) {
	## ($bmv, $emv) = ($_[0],$_[1]);
	if($CFG{'trace'}) {
	    print "ROR Trace: Perf calc #1 of 1:\n";
	    print "BMV = $_[0]\n";
	    print "EMV = $_[1]\n";
	    print "ROR = " . _decimal_to_pct(($_[1]-$_[0])/$_[0]) . " ( (EMV - BMV)/BMV, ($_[1]-$_[0])/$_[0] )\n";
	}
	return _decimal_to_pct(($_[1]-$_[0])/$_[0]);
    }

    ## Validate args
    my %args = @_;
    if (!defined($args{'bmv'})) {
	push @{$args{'errs'}}, "Required argument 'bmv' not specified";
    }
    if (!defined($args{'emv'})) {
	push @{$args{'errs'}}, "Required argument 'emv' not specified";
    }
    if ($args{'errs'}) {
	croak join("\n",@{$args{'errs'}});
    }

    my @rors = ();

    ## Treat bmv and emv as cash flow zero events at the boundry points.
    unshift @{$args{'flows'}},{mvpcf=>$args{'bmv'},cf=>0.0};
    push    @{$args{'flows'}},{mvpcf=>$args{'emv'},cf=>0.0};

    my $idx = undef;
    for (my $i = 0;$i<scalar(@{$args{'flows'}})-1;$i++) {

	## If you are looking for optimizations, don't bother trying
	## to replace the 'my' vars. I tried it, it wasn't faster.
	my $bmv = $args{'flows'}->[$i]->{mvpcf} + $args{'flows'}->[$i]->{cf};
	my $emv = $args{'flows'}->[$i+1]->{mvpcf};
	push @rors, ($emv - $bmv)/$bmv;
	if($CFG{'trace'}) {
	    print "ROR Trace: Perf calc #" . ($i+1) . " of " . (scalar(@{$args{'flows'}})-1) . ":\n";
	    print "BMV = $bmv (mvpcf $args{'flows'}->[$i]->{mvpcf} + cf $args{'flows'}->[$i]->{cf})\n";
	    print "EMV = $emv (mvpcf $args{'flows'}->[$i+1]->{mvpcf})\n";
	    print "ROR = $rors[-1] ( (EMV - BMV)/BMV, ($emv - $bmv)/$bmv )\n";
	}
    }
    return link_ROR(@rors);
}

sub link_ROR {
    ## Use @_ and save the memcopys.
    ## my @returns = @_;
    my $ror = (map{$_+1.00} map{_pct_to_decimal($_)} shift )[0];
    my $idx = 1;
    for(map{$_+1.00} map{_pct_to_decimal($_)} @_) {
	print "Link @{[$idx++]} of @{[scalar(@_)]}: $ror * $_ = " if ($CFG{'trace'});
	$ror *= $_;
	print "$ror\n" if ($CFG{'trace'});
    }
    return _decimal_to_pct($ror - 1.0);
}

sub ized_ROR {
    ## Save the memory copy by using @_
    ## my ($ror,$periods) = ($_[0],$_[1])
    return _decimal_to_pct(((_pct_to_decimal($_[0])+1.0) ** (1.0/$_[1]))-1);
}

sub _pct_to_decimal {
    my $decimal = $_[0];
    $decimal =~ s|(.*)%|$1/100.|e;
    return $decimal;
}

sub _decimal_to_pct {
    return ($CFG{'return_percentages'}
	    ? ($_[0] * 100) . '%'
	    : $_[0]);
}

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Finance::Performance::Calc - Perl extension to calculate linked performance numbers.

=head1 SYNOPSIS

  use 5.006001;
  use Finance::Performance::Calc qw (:all);

  print ROR(bmv => 20_000, emv => 21_567.87)
  # or, for convenience
  print ROR(20_000, 21_567.87);


  print ROR(bmv => 20_000, emv => 21_567.87,
	    flows => [
		      {mvpcf => 20_345,
		       cf    => 1000},
		      {mvpcf => 23_500,
		       cf    => -3000}
		     ]);

  print link_ROR(0.017,0.234,'-3.4%');

  print ized_ROR(0.07,5);

  Finance::Performance::Calc::return_percentages(1);
  print ROR(20_000,21_567.87);

  print ROR(bmv => 20_000, emv => 21_567.87,
	    flows => [{mvpcf => 20_345,
		       cf    => 1000},
		      {mvpcf => 23_500,
		       cf    => -3000}
		     ]);

  print link_ROR(0.017,0.234,'-3.4%');

  print ized_ROR(0.07,5);


=head1 DESCRIPTION

This module allows you to calculate performance for number of situations:

Single period performance, given a beginning market value (BMV) and
ending market value (EMV) and optional cash flows in between.

Linked periodic performance; i.e, given three consecutive monthly
returns, calculate the performance over the quarter.

"ized" performance. Given a rate of return that covers multiple
periods, calculate the per-period return.

The formulae are taken from the book "Measuring Investment
Performance". Author: David Spaulding. ISBN: 0-7863-1177-0.

B<NOTE> Before using in a production environment, you should
independently verify that the results obtained match what you
expect. There may be unintentionally made assumptions in this code
about timing and precision and what-not that do not match your
assumptions with respect to the calcualtions.

=head2 FUNCTIONS

=over 4

=item ROR

 my $ror = ROR($bmv, $emv, @flows);

Rate Of Return. Given a beginning market value ($bmv) and an ending
market value ($emv), the rate of return is calculated as

 ($emv - $bmv)/$bmv

If there are intervening cash flows between the beginning market value
and the ending market value, they are each represented by a hash ref
containing the keys 'mvpcf' (market value prior to cash flow) and 'cf'
(cash flow). The return is caculated by determining the rate of return
between each cash flow and then linking the returns together. In this
case, the beginning market value and the ending market value are
treated as zero cash flow events; that is:

 EMV is treated as {mvpcf => EMV, cf => 0}
 BMV is treated as {mvpcf => BMV, cf => 0}

The rate of return is in decimal form (0.02) for a return of two
percent (2.0%).

=item linked_ROR

 my $ror = linked_ROR(0.02, -0.02, '3.5%');

Given previously calculated multiple rates of return, calculate the
overall rate of return. The rates are linked using the algorithm:

o Convert any percentages to decimal (/100).

o Add 1.00 to each rate

o Multiply all the rates together

o Subtract 1.00 from the result

o Convert to percentage (* 100)

The function properly interprets strings with percents signs by
dividing by 100 before using the value in any calculation.

The rate of return is in decimal form (0.02 for a return of two
percent).

=item ized_ROR

 my $ror = ('7.0%',12);

Given a rate of return, and a number of periods, calculate the rate of
return for each period.  In our example, the 7.0% return is annual. We
want to find the monthly return (12 months in one year). The calculation is:

 ((ROR + 1.0) ** (1.0/numPeriods)) - 1.00;

The rate of return is in decimal form (0.02 for a return of two
percent).

=back

=head2 GLOBAL CONFIGURATION

=over 4

=item return_percentages

If this function is called with an argument of 1, all of the rates of
return that are returned from the functions will be strings in
percentage form; i.e. '7.45%' instead of 0.0745. Setting to 0 turns
this off. This eliminates the need for doing the math and adding the
percent yourself in a known display circumstance.

If called with arguments, the B<prior> value is returned.

If called with no arguments, the current value is returned.

=item trace

If this function is called with an argument of 1, the steps in ROR and
link_ROR will be printed as they are executed. This does impose a
speed penalty. Setting to 0 turns this off.

If called with arguments, the B<prior> value is returned.

If called with no arguments, the current value is returned.

=head2 CAVEATS

=over 4

The module does not do any extra special handling with regards to
precision. The first example above

  print ROR(20_000,21_567.87);

happily returns a value of

 0.0783934999999999

on my Linux box. In matters of precision, you have two choices:

=item 1

Use regular Perl scalar floats as arguments and round the final result.

=item 2

Use numeric objects whose behavior can be controlled as arguments. The
only requirements for such an object are that addition, subtraction,
multiplication and division ae overloaed for the object. For example:

 use Math::FixedPrecision;
 print ROR(new Math::FixedPrecision(20_000),
           new Math::FixedPrecision(21_567.87));

results in

 0.08

Two (and only two) decimal places are returned because the most
precise term is the 21_567.87 value, two decimal places.

If you want more precision, ask for it:

 use Math::FixedPrecision;
 print ROR(new Math::FixedPrecision(20_000),
           new Math::FixedPrecision(21_567.87,4));

resulting in

 0.0784

Be forewarned that using numeric objects as opposed to native Perl
numeric data types can result in loss of speed (see the example script eg/eg.pl in
the distribution). YMMV. Test before using in a production scenario.

=back

=head1 SEE ALSO

L<perl>.

=head1 AUTHOR

Matthew O. Persico, E<lt>persicom@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Matthew O. Persico

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.6.1 or,
at your option, any later version of Perl 5 you may have available.

Before using in a production environment, you should independently
verify that the results obtained match what you expect. I have to the
best of my ability checked the results of this module, but I do not
present any warrantee or guarrantee that the module is free from
error.

=cut
