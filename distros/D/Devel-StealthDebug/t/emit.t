use Test::More   tests => 1;
use File::Temp "tempfile";
use Devel::StealthDebug emit_type=>'print';

close STDOUT;
my ($fh,$fn) = tempfile() or die $!;
open (STDOUT, "> $fn") or die $!;

my $donothing='whatever'; #!emit(print ok)!;
close STDOUT;

open (STDIN,"< $fn");
my $out	=<STDIN>;
close STDIN;

like($out, qr/print ok/);
