#
# Not authorized in t/debug.t
# should not execute debug code (which is identical to t/debug.t btw)
#
use Test::More   tests => 1;
use File::Temp "tempfile";
use Devel::StealthDebug emit_type=>'print',ENABLE=>$ENV{IHOPETHISVARISNTSETONYOURHOST};

close STDOUT;
my ($fh,$fn) = tempfile() or die $!;
open (STDOUT, "> $fn") or die $!;

my $donothing='whatever'; #!emit(print ok)!;
close STDOUT;

open (STDIN,"< $fn");
my $out	=<STDIN>;
close STDIN;

unlike($out, qr/print ok/);
