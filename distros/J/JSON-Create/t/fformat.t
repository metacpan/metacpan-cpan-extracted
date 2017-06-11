use warnings;
use strict;
use utf8;
use FindBin '$Bin';
use Test::More;
my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";
binmode STDOUT, ":encoding(utf8)";
binmode STDERR, ":encoding(utf8)";
use JSON::Create;

my $jc = JSON::Create->new ();
my @array = (1000_000_000.0, 100_000_000.0, 10_000_000.0, 1_000_000.0, 100_000.0, 10_000.0, 1000.0, 100.0,10.0,1.0,0.1,0.01,0.001,0.0001,0.000_01,0.000_001,0.000_000_1,0.000_000_01,0.000_000_001);
#$jc->set_fformat ('%f');
#my $fout = $jc->run (\@array);
#note $fout;
$jc->set_fformat ('%e');
my $eout = $jc->run (\@array);
my $e = qr/
	      (?:
		  [1-9]
		  # It may or may not have a ".0" part.
		  (?:\.[0-9]*)?
		  e
		  (?:\+|-|)
		  [0-9]+
	      )
	  /x;

my $eout_re = qr/
		    ^\[
		    (?:
			$e,
		    )*
		    $e
		    \]$
		/x;

like ($eout, $eout_re, "%e format output looks like it should");
#note $eout;
# $jc->set_fformat ('%2.4g');
# my $gout = $jc->run (\@array);
# note $gout;
# $jc->set_fformat ('%2.10g');
# my $glout = $jc->run (\@array);
# note $glout;
# http://www.geom.uiuc.edu/~huberty/math5337/groupe/digits.html
my $pi = '3.141592653589793238462643383279502884197169399375105820974944592307816406';
my @piarray = map {$pi * $_} @array;
my $glpout = $jc->run (\@piarray);
#note $glpout;
$jc->set_fformat ('%2.10e');
my $elpout = $jc->run (\@piarray);
#note $elpout;
like ($elpout, $eout_re, "%2.10e looks like e format");

badformat ($jc, '%2.100g');
badformat ($jc, 'Magnum PI');

done_testing ();
exit;

sub badformat
{
    my $warned;
    my ($jc, $format) = @_;
    $SIG{__WARN__} = sub { $warned = "@_"; };
    $jc->set_fformat ($format);
    ok ($warned, "warning with $format");
}

