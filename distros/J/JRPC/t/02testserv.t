
use Test::More;

use Data::Dumper;$Data::Dumper::Indent = 0;$Data::Dumper::Terse = 1;
use threads;
use strict;
use warnings;
# Setup to run flexibly in topdir or t/
use lib('..', './examples', '../examples');

#my $can_use_threads = eval 'use threads; 1';
#if (!$can_use_threads) {plan('skip_all', "Cannot use threads !");}
require("SimpleMath.pm");
#if (!$SimpleMath::VERSION) {plan('skip_all', "Cannot use threads !");}
plan('tests', 12); # 10,12
use_ok('JRPC');
use_ok('JRPC::Client');
JRPC::setup_pkg_as_server('SimpleMath');
my $port = $ENV{'JRPC_SIMPLEMATH_PORT'} || 9000;
note("Looking to run SimpleMath under port $port (Change by setting JRPC_SIMPLEMATH_PORT)");
my $testreqcnt = 0; # MUST Match actual cnt of runrequest() when using non-0
my $runserver = sub {
   my ($port) = @_;
   # MUST (?) Set in this thread (because of no data sharing betw. Perl threads).
   # $JRPC::CGI::dieaftercnt = $testreqcnt;
   threads->set_thread_exit_only(1); # Seems to be default
   # Use signaling to kill thread ?
   $SIG{'KILL'} = sub { threads->exit(); };
   SimpleMath->new($port)->run();
   print(STDERR "Done run()\n"); # Never seen
};
#NONTHREADED:$runserver->();

my $thr = threads->create($runserver, $port);
my $client = JRPC::Client->new();
my $url = "http://localhost:$port";
runrequest($client, $url, 'Math.add', [1,2], {'res' => 3});
runrequest($client, $url, 'Math.add', [4,7], {'res' => 11});
#note("At Join Point (waiting ...)\n");
note("Ran Client tests sequentially\n");
#my @threads = threads->list(threads::running); # threads::running threads::joinable
#print(Dumper(\@threads));
#threads->exit(); # Does not work here. immediate exit
#$thr->join();
$thr->kill('KILL')->detach();
note("Stopping main thread, exiting\n");
exit(0);

# Testing routine witch checks on client-server interaction
sub runrequest {
   my ($client, $url, $meth, $p, $exp) = @_;
   my $req = $client->new_request($url);
   isa_ok($req, 'HTTP::Request');
   my $resp = $req->call($meth, $p, 'debug' => 0);
   ok($resp, "Got JSON-RPC Response ($resp)");
   ok($resp->{'_parsed_content'}, "Client Has Parsed JSON Content");
   DEBUG:note("Resp. Content (raw,unparsed JSON): ".$resp->content());
   my $error = $resp->error();
   my $result = $resp->result();
   if (my $err = $resp->error()) { die($err->{'message'}); }
   my $res = $resp->result();
   note("JSON-RPC Result (Perl RT):". Dumper($res));
   ok($res->{'res'}, "result has 'res' member");
   is_deeply($res, $exp, "Result matches expected");
}
