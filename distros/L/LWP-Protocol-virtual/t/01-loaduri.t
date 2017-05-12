
use Test::More tests => 4, import => ['!fail'];
use lib "lib";
use LWP::Simple;
use URI;
use URI::virtual;
use strict;

my $tstdir = "file://$ENV{PWD}/t";
my $relurl = "01-loaduri.cfg";
my $tstcfg = "loaduri $tstdir";

{
	open(my $CFG,">t/01-loaduri.cfg");
	print {$CFG} $tstcfg, "\n";
	close($CFG);
}
URI::virtual::lists(qw(./t/01-loaduri.cfg));
my ( $uri, $res );
ok($uri=URI->new("virtual://loaduri/01-loaduri.cfg"));
ok(ref $uri eq "URI::virtual");
ok($res = $uri->resolve()->canonical());
ok(substr($res,0,length($tstdir)) eq $tstdir);
diag("res=$res\ntestdir=$tstdir\n");
1;
