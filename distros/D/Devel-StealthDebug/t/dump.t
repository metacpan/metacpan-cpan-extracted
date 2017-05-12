use Test::More;
use vars qw($TESTS);

BEGIN {
	$TESTS = 13;
	plan tests => $TESTS;
}

use File::Temp "tempfile";
use Devel::StealthDebug emit_type => 'print';

close STDOUT;
my ($fh,$fn)= tempfile() or die $!;
open (STDOUT, "> $fn") or die $!;

my %var;
$var{scalar}=3;
$var{array}=['','b',3];
$var{hash}={a=>'b',b=>'c',c=>'d'};

my $donothing='whatever'; #!dump(\%var)!;
close STDOUT;
open (STDIN,"< $fn");
my ($out,$check);
for(1..$TESTS) {
	$out	= <STDIN>;
	$check 	= quotemeta(<DATA>);
	like($out , qr/$check/);
}
close STDIN;
__DATA__
$\%var = {
  'array' => [
    '',
    'b',
    3
  ],
  'hash' => {
    'a' => 'b',
    'b' => 'c',
    'c' => 'd'
  },
  'scalar' => 3
};
