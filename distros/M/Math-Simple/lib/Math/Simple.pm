#!/usr/bin/perl

=encoding utf-8

=head1 NAME

Math::Simple  -  Very simple, commonly used math routines

=head1 VERSION

Version "2.1.2"

=cut

###############################################################
#	Changes
#	- 2.1.2 - removed spurious inclusion of uneeded header (Types::Core)
#	- 2.1.1 - reformat header as it didn't seem to index properly
#	- 2.1.0 - add gcd function;  
#					- Update docs &  clarify logb usage
#					- added more tests to test suite
#	- 2.0.3 - change min & max to handle an Array ref as 1st arg
#	- 2.0.2 - change logb to be a default export as it is basis for 
#						all other log bases (i.e. - log2, log10, log1024...etc)
# - 2.0.1 - minor typo's
#	- 2.0.0	- First public release (no tests yet)
#
package Math::Simple;
our $VERSION='2.1.2';

{ 


	our @__baselogs__;
	BEGIN {
		require $_.".pm" && $_->import for qw(strict warnings);
		$__baselogs__[10]=log(10);
		$__baselogs__[2]=log(2);
	}
	our @EXPORT = qw(max min logb log10 gcd);
	our @EXPORT_OK = qw(log2 );
	use Xporter;

	{
		sub logb($;$){
			die "logb requires 1 or  2 params" unless @_;
			if (@_==2) {
				return log($_[1]) / ($__baselogs__[$_[0]] ||= log $_[0]) }
			elsif ( @_==1) {
				my $base = $__baselogs__[$_[0]] ||= log $_[0];
				return sub ($) {
						log($_[0]) / $base;
					}
				}
		}
	}

	BEGIN {
		sub log2 ($)  { logb(2, $_[0]) }
		sub log10 ($) { logb(10, $_[0]) }
	}
	sub max ($;@);
	sub min ($;@);

  sub max ($;@) { @_ == 2 and return  $_[0] >= $_[1] ? $_[0] : $_[1]; 
                  @_ == 1 and return $_[0];
                  max( max(pop @_, pop @_), @_); 
                }

  sub min ($;@) { @_ == 2 and return  $_[0] <= $_[1] ? $_[0] : $_[1]; 
                  @_ == 1 and return $_[0];
                  min( min(pop @_, pop @_), @_); 
                }
	sub gcd($$) {
		my ($sign, $num, $den, $gcd) = (1, @_);
		if ($num == 0) { $den=$gcd=1 }
		elsif ($den) {
			if ($den < 0) {$num	= -$num,$den = -$den}
			if ($num < 0) {$sign= - 1, 	$num = -$num}
			my ($x, $y) = $num<$den ? ($num,$den) : ($den, $num);
			my $m; while ($y && ($m = $x % $y)) {$x = $y; $y = $m}
			$gcd = $y;
		} else {$gcd=1, $num=0, $den=1}
		unless ($gcd) {$gcd=1; return 1}
		$num /= $gcd*$sign; $den /= $gcd;
		$gcd;
	}
1}
###########################################################################
#             Pod documentation           {{{1
#    use Math::Simple

=head1 SYNOPSIS

 use Math::Simple qw(log2);
 my $low            =  min($a,$b, $c, $d ...);    # least positive num
 my $hi             =  max($a,$b);                # most positive num
 my $digits_ƒ       =  sub ($) {int log10($_[0]); # log10 default export  
 my $log_in_base    =  logb($base,$num);          # log arbitrary base
 my $log16_ƒ        =  logb(16);                  # create log16 func 
 my $bits_needed_ƒ  =  sub ($) {int log2($_[0])};
 use constant nbits => log2(~1);                  # compile constant
 my $gcd            =  gcd(42,12)

=head1 DESCRIPTION

Very simple math routines that I end up re-using in many progs and
libified for easy access.  

Most of the functions are exported by default, with easy options
to unexport the ones you don't.
As of this version, default exports are C<min>, C<max>, C<log10>, C<logb>,
and C<gcd>, with C<log2> being an optional export.

I<Note> on the C<logb> function. It returns a function or a result
based on the number of inputs.  If one input is given, it is a
logarithm function factory -- producing a specialized, or I<curried>
log function for the base given.  If the C<logb> function is given
two parameters, it will return the logarithm of the second
number in the base of the first.

C<Math::Simple> uses L<Xporter>, so including C<log2> or 
any future additions won't break the default C<EXPORT> list see L<Xporter>.


=head2 Performance Note

In order to calculate the log in another base, one must first take
the log of the base in a known base (C<Perl>'s natural logarithm function
is used for this).  This means that non-natural logarithm bases normally
require 2 logarithms/call, however, the bases are cached the first
time used so future calls will only need the logarithm function called
on the new data.  

=cut


