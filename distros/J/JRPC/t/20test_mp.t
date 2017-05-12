# Examples of running ab on JRPC service (esp. interesting for mod_perl mode)
# export QMP_HOST=localhost
# export QMP_DEBUG=1
# ab -c 10 -n 100 -T text/json -p test_add.json http://$QMP_HOST/Math
# ab -c 10 -n 100 -T text/json -p test_mult.json http://$QMP_HOST/Math
# TODO: Convert to spawn HTTP::Server::Simple to remove heavy server-side dependencies.
# TODO: See the reason for: Subroutine CGI::uri redefined at (eval 22) line 1, <DATA> line 16.
use Test::More;
use LWP;
#use WWW::Mechanize;
use JSON::XS;
#use Scalar::Util;

use strict;
use warnings;
# Msg for Math.add
my $msg = {'id' => $$, 'method' => 'add', 'params' => [12,22], 'jsonrpc' => '2.0'};
# 
my $host = $ENV{'QMP_HOST'}; # || 'localhost';

if (!$ENV{'QMP_HOST'}) {plan('skip_all', "Need QMP_HOST for host to be tested");}
eval("use WWW::Mechanize;");
if ($@) {plan('skip_all', "No WWW::Mechanize found in system");}
my $url = "http://$host/Math";
plan('tests', 8);
my $debug = $ENV{'QMP_DEBUG'} || 0;
note("Set QMP_DEBUG in environment to debug HTTP traffic (Currently: QMP_DEBUG=$debug)");
# For starters, use Plain WWW::Mechanize to test the JSON-RPC server side. TODO: Use JRPC::Client directly
my $mech = WWW::Mechanize->new('cookie_jar' => {}, 'keep_alive' => 1, );
{
  my $jsoncont = encode_json($msg);
  ok($jsoncont, "Sending(sum): $jsoncont");
  my $resp = $mech->post($url, 'Content' => $jsoncont);
  #my $hdrs = $resp->...;
  #ok($resp, "$resp");
  isa_ok($resp, "HTTP::Response");
  if ($debug) {$mech->dump_headers();}
  my $cont = $mech->content(); #    $mech->response->decoded_content();
  ok($cont, "Got Response: $cont\n");
  my $js = decode_json($cont);
  ok(ref($js) eq 'HASH', "Got Object ($js)");
}
{
  my $url = "http://$host/qmp";
  # Params only
  my $p = {'_class' => 'employee', 'name' => 'John', 'address' => 'Hickory Street 1212'};
  $msg->{'params'} = $p;$msg->{'method'} = 'store';
  my $jsoncont = encode_json($msg);
  ok($jsoncont, "Serialized JSON Content to send: $jsoncont");
  #print("Sending(store): $jsoncont\n");
  my $resp = $mech->post($url, 'Content' => $jsoncont);
  isa_ok($resp, "HTTP::Response");
  my $cont = $mech->content();
  ok($cont, "Got Response: $cont\n");
  if ($debug) {$mech->dump_headers();}
  #print("$cont\n");
  my $js = decode_json($cont);
  ok(ref($js) eq 'HASH', "Got Object ($js)");
}
1;
