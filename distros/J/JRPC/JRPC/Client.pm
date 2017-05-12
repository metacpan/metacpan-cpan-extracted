# Send Requests to a JSON-RPC Service.
# We completely ride on the wonderful LWP Module.
{
package JRPC::Client;
#
use LWP;
use LWP::UserAgent;
use base ('LWP::UserAgent');
use JSON::XS;
use Data::Dumper;

#our $mime;
#BEGIN {
# De-facto JSON-RPC Mime type
our $mime = 'application/json';
#};

=head1 NAME

JRPC::Client - JSON-RPC 2.0 Client

=head1 SYNOPSIS

   use JRPC::Client;

   my $client = JRPC::Client->new();
   $req = $client->new_request("http://jservices.com/WorldTime");
   my $resp = $req->call('Timeinfo.getlocaltime', {'tzname' => 'CET', 'clockhrs' => '24'});
   if (my $err = $resp->error()) { die("$err->{'message'}"); }
   my $res = $resp->result();
   print("Local time in CET is: $res->{'timeiso'}\n");

=head1 DESCRIPTION

JRPC::Client is a Perl LWP based JSON-RPC 2.0 Client hoping to minimize tedious boilerplate code for JSON-RPC
interaction, yet enabling advanced use cases by the power of LWP / HTTP::Request.

JRPC::Client complies to conventions of JSON-RPC 2.0, but it can be coerced to be used for other versions as well.

=head2 $client = JRPC::Client->new()

Instantiate a new JSON-RPC (2.0) Client.
HTTP keep-alive is turned on, cookie store is established and
default user-agent name is set here.
Any of the LWP::UserAgent methods are callable on the returned object as JRPC::Client IS-A LWP::UserAgent.

The lifetime of the JRPC::Client can be kept long (e.g. throughout app) and it can usually be kept as single instance
in app runtime (singleton, however JRPC::Client does not control singularity of instantiation).
The factory method method new_request() takes care of instatiating requests for various URL:s, various methods.

=cut
sub new {
  my ($class, %c) = @_;
  my $ua = LWP::UserAgent->new('keep_alive' => 1, 'cookie_jar' => {});
  $ua->agent("JSON-RPC Client/0.9");
  if ($c{'jsonrpc'}) {$ua->{'_jsonrpc'} = $c{'jsonrpc'};}
  # Re-bless ...
  return bless($ua, $class);
}

=head2 $req = $client->new_request($url, %opts)

Factory method to instantiate and prepare a new JSON-RPC request to a URL. Options in %opts:

=over 4 

=item * 'mime' - Mime content-type for request (default: 'application/json')

=item * 'debug' - Dump Request after instantiation (to STDERR).

=back



=cut
sub new_request {
   my ($ua, $url, %c) = @_;
  # 'mime' - Special mime type to use (default: 'application/json')
  my $req = HTTP::Request->new('POST', $url);
  
  $req->content_type($c{'mime'} || $mime); # text/plain
  #if ($c{'cred'}) {$req->header('Authorization', "Basic $c{'cred'}");}
  # Need to associate agent to request for call-phase
  $req->{'_ua'} = $ua;
  # Rebless to JRPC::Client::Request. @ISA / use base takes care of HTTP::Request methods being callable.
  bless($req, 'JRPC::Client::Request');
  if ($c{'debug'}) {print(STDERR Dumper($req));} # Store persistently: $req->{'_jsonrpcdebug'} = $c{'debug'};
  # Verification / Sanity check
  if (!$req->isa('HTTP::Request')) {die("NOT a HTTP::Request");}
  return($req);
}

};
############# 
{
package JRPC::Client::Request;
use Data::Dumper;
use JSON::XS;
use strict;
use warnings;
our @ISA = ('HTTP::Request');
our $id = 1;
our $debug = 0;

# NOTREALLY: Override the famous is_success() / is_error() methods.
# Because the JSON-RPC is higher level than HTTP, we are not talking about
# about HTTP success (200 success vs. 500 Error), but JSON-RPC success/error.
# NEW: This is probably bad idea as is_success / is_error are very established
# and besides useful for detecting HTTP level errors.
#sub is_success {
#   my ($req) = @_;
#   
#}

=head2 $resp = $req->call($method, $params, %opts)

Call a method previously prepared as a HTTP::Request on a URL (see new_request()).
The JSON-RPC parameters passed as $param may be either a perl data structure (reference) or a filename (string).

=over 4

=item * Valid JSON string

=item * a Perl runtime data-structure with JSON serializable elements.

=back

In either case above (as a bit of forgiving behaviour) also passing a complete
JSON-RPC message is allowed for covenience. A complete JSON-RPC message is
detected by the presence of members 'id', 'jsonrpc', 'params' and 'method', which
(especially all at the same time, together) are extremely unlikely to appear
in the parameters. In the case of passing a complete message, the method found in
message overrides the $meth passed params.

Optional KW parameters in %opts:

=over 4

=item * notify - Treat call as JSON-RPC notification. Ignore response (do not parse it).

=item * debug - Produce debug output for call() phase

=back

Note: on regular call (i.e. non-notification by 'notify' => 0) call() method parses the JSON
response and expects it to be valid JSON, but it does not validate the JSON-RPC envelope
(for presence of mandatory members).

Return (LWP) HTTP response object.

Further access by $resp->result() will evaluate the validity of the envelope.

=cut
#  the "params" section of JSON-RPC message or
# for convenience a complete JSON-RPC message (i.e. envelope with members "jsonrpc","method","id","params").
# TODO: Support non-forgiving behaviour.
sub call {
   my ($req, $meth, $param, %c) = @_;
   my ($msg, $pp, $len);
   my $isref = ref($param);
   #if ($isref) {}
   # Risk it and accept string form json as likely prevalidated JSON.
   # Die on parsing errors by JSON::XS.
   if (!$isref && $param =~ /^\s*{/) {
      $pp = eval { decode_json($param); };
      if ($@) {die("Error In JSON params passed as string");}
   }
   elsif ($isref) {$pp = $param;}
   else {die("Malformed JSON body ($param)");}
   my %enpara = ();
   if ($c{'id'}) {$enpara{'id'} = $c{'id'};} # Allow explicit id
   # Forgiving mode - accept complete message
   if (is_message($pp)) {$msg = $pp;}
   else {$msg = envelope($meth, $pp, %enpara);}
   # eval for catching serialization errors (for example blessed
   # branches w/o TO_JSON for type).
   my $body = eval { encode_json($msg); };
   if ($@) {die("Error Serializing message: $@");}
   $len = length($body);
   #my $len = length($body);
   $req->content($body);
   $req->header('content-length', $len);
   my $ua = $req->{'_ua'};
   if (!$ua) {die("Missing User-Agent for call() phase");}
   ############# Launch Request !
   my $res = $ua->request($req);
   if ($c{'debug'}) {print(STDERR Dumper($res));}
   # Call directly ... Request:..
   if ($res->is_success()) {
      # Parse Response in case of success
      # (OR ALWYAYS on any HTTP status ?)
      if ($debug || $c{'debug'}) {print(STDERR "Response-Content:\n=====\n".$res->content()."\n=====\n");}
      # Allow request to be a notification - Ignore response and do NOT parse it.
      # In this case Client should not call $resp->result()
      if ($c{'notify'}) {return($res);} # Or goto 
      my $respmsg = $res->{'_parsed_content'} = eval { decode_json($res->content()); };
      if ($@) {die("Error parsing reponse: $@");}
      #$res->{'_parsed_content'}
      # Even in case of is_success() true, check for 'error' (exception)
      #if (my $error = $respmsg->{'error'}) {
      #   $res->{'_parsed_response'} = $error;
      #}
      #else {
      #   $res->{'_parsed_response'} = $respmsg->{'result'};
      #}
   }
   # HTTP Errors (as interpreted by LWP)
   else {die("JSON-RPC Error: ".$res->status_line());}
   return($res);
}

=head1 RESPONSE METHODS

These methods magically appear in the HTTP::Response for the purposes of
JRPC::Client::Request.

=cut

#=head2 $resp->parsed_content();
sub HTTP::Response::parsed_content {
   return($_[0]->{'_parsed_content'});
}

=head2 $resp->result()

JSON_RPC response "result" (as native data structure)

=cut
sub HTTP::Response::result {
   return($_[0]->{'_parsed_content'}->{'result'});
}

=head2 $resp->error()

JSON_RPC response "error" (as native data structure)

=cut
sub HTTP::Response::error {
   return($_[0]->{'_parsed_content'}->{'error'});
}


=head1 INTERNAL METHODS

These methods should not be of interest to a user of the productivity API
(as demonstrated in SYNOPSIS).

=head2 is_message($msg)

Internal check to see if the passed structure looks like a JSON-RPC message envelope.
To do so, the handle must be a ref to a hash and contain envelope parameters
'id', 'jsonrpc', 'params' and 'method'.
is_message() is used to differentiate between complete
messages and parameters-only to provide a forgiving behaviour on higher level
functions (see call() method)

=cut

sub is_message {
   my ($m) = @_;
   # MUST Also be a ref eq 'HASH'
   if (ref($m) ne 'HASH') {return(0);}
   return($m->{'id'} && $m->{'jsonrpc'} && $m->{'params'} && $m->{'method'});
}

=head2 envelope($meth, $params, %opts)

Internal method to generate message envelope for method $meth and parameters passed.
The $params should be checked by is_message() first to have the correct
(non double wrapped) envelope created here.

Method in $meth must be passed to generate message envelope.

=cut
sub envelope {
   my ($meth, $params, %c) = @_;
   if (!$meth) {die("No 'method' member for envelope");}
   my $msg = {'jsonrpc' => '2.0', 'method' => $meth, 'params' => $params, };
   # Add ID - Either sequential / auto incrementing  or explicitly passed.
   $msg->{'id'} = $c{'id'} || ++$id;
   return($msg);
}



}; # end of JRPC::Client::Request
1;
