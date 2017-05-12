#{
package JRPC;
use JSON::XS;
use Data::Dumper;
use strict;
use warnings;

#UNUSED:my $rstub = {'id' => 66666, 'jsonrpc' => '2.0'};
our $VERSION = '0.61';
# 0 = No validation (trust client, any exceptions thrown because of errors will
#    be much lower level.)
# 1 = Validate method,params
# 2 = Require 'id','jsonrpc', 3 
our $msgvalid = 1;
# This is prelogger callback. MUST be a _hard_ CODE ref to be used (not symbolic reference).
our $prelogger;

=head1 NAME

JRPC - Create JSON-RPC Services focusing on app logic, not worrying about the details of JSON-RPC Processing.

=head1 SYNOPSIS

   use JRPC;
   # Load one of the Service modules JRPC::CGI, JRPC::Apache2 or JRPC::Nginx
   # See particular submodule documentation for the details.
   use JRPC::CGI;

=head1 DESCRIPTION

JRPC Module bundle consists of Server and Client pieces for creating JSON-RPC services.
For the server piece it takes a slightly different approach than many other "API Heavy" CPAN modules.
Instead of assembing your service out of API calls, JRPC forms a framework on top of your implementation and
allows you to write a (single) callback:

=over 4

=item * receiving parameters (JSON-RPC "params") of the of JSON-RPC call pre-parsed, ready-to be worked with by your app code

=item * returning the "result" data (to framework taking care of JSON-RPC)

=back

The callback should be wrapped into a class package. One package can host multiple service methods.

When any exception is thrown (by die()) during the processing by callback, the framework takes care of turning this to an appropriate JSON-RPC fault.
The framework will also take care of dealing with JSON-RPC "envelope" (term borrowed from SOAP lingo) of both request and response, "unwrapping" it
on request and wrapping the result with it on response.

   package MyEchoService;
   our $VERSION = '0.01';
   
   # Respond with whatever was sent
   sub echo {
      my ($param) = @_;
      # Pass-through - Just send the "params" as "result"
      return($param);
   }

=head1 DISPATCHING OF SERVICE REQUEST

Dispatching of service request can use 2 methods:

=over 4

=item * URL based dispatching, where relative URL (after server name and port) defines the package and method name ("method" in JSON-RPC envelope) defines the runtime method

=item * URL independent dispatching where method name with dot-notation defines the method name

=back

Currently the dispatching method is automatically chosen based on what is found in "method" member of JSON-RPC envelope.
Examples highlighting the (automatically) chosen dispatching method:

=over 4

=item * "method": "echo", URL "/MyEchoService" - Choose URL based dispatching, map relative URL to package and echo() method ( MyEchoService::echo() )

=item * "method": "MyEchoService.echo" - Derive both Class and method from dot-notation ( MyEchoService::echo() )

=back

I'd recommend the latter as a more modern way of dispatching. Additionally (because of URL independence and need to "map" URL:s) it is less likely to require config changes in your web server.

=head1 METHODS

=head2 createfault($req, $msg, $errcode)

Internal method to create a JSON-RPC Fault message.
As these parameters are coming from the server side code, they are trusted
(i.e. not validated) here. Parameters:

=over 4

=item * $msg - Message (typically originating from exceptions). Placed to member "message" of
"error" branch of fault (See JSON-RPC 2.0 spec for details).

=item * $errcode - Numeric error code (must be given)

=back

Notice that the service methods should not be using this directly, but only be throwing exceptions.
As a current shortcoming, the service methods cannot set $errcode (Only basic string based exceptions are
currently allowed / accepted).

This should not be called explicitly by service developer. Throw execptions in your service handler to have them
automatically converted to valid JSON-RPC faults by createfault().

=cut
# =item * $data - ANY data to be attached to 'data' member of error/fault Object
sub createfault {
   my ($req, $msg, $errcode) = @_; # , $data
   # Create response stub  HERE ????
   # TODO: We could clone original or just pick 'id', 'jsonrpc' from it.
   my $resp = {'jsonrpc' => '2.0'}; # $req ? $req : Storable::dclone($rstub);
   $resp->{'id'} = $req->{'id'};
   #$req->{'id'} = $msg->{'id'};
   my $fault = $resp->{'error'} = {'message' => $msg, 'code' => $errcode, };
   #if ($data) {$fault->{'data'} = $data;}
   # Return data (structure) or serialized JSON ?
   #if (1) {}
   return(encode_json($resp));
   # Return apache return values, such as Apache2::Const::OK ?
}
# Note - these package global lazy-cached tables have different formats.
# Single level dot-notation to service method (CODE) mapping.
our %dotn2func = ();
# Two level URL => method => service method (CODE) mapping.
our %urlm2func = ();

#=head1 METHOD RESOLVER METHODS

#Both resolvers (Explained earlier in doc) are able to cache package+method combos in lookup tables for accelerated resolution.
# Both have their own cache / mapping table (containing re-resolved methods) for this purpose.
#Both resolver methods return a hard (CODE) reference to service for the server to execute.

# DONE: Build a pre-resolved method mapping table.
# TODO: Allow 'lazyload' for lazily loading modules on-demand.
# Should we do package AND method resolution in single method ?
sub methresolve_dotnot {
   my ($r, $m) = @_;
   # Support dot-notation (resolve_dotnot())
   if ($m !~ /\./) {die("No dot-notation in method");} # Redundant check
   # Resolved earlier, Pre-cached ?
   if (my $f = $dotn2func{$m}) {return($f);}
   my @pp = split(/\./, $m);
   my $mcp = pop(@pp); # pop() (trailing) method
   
   if (!$mcp) {die("No method remaining for dotnot method resolution ($m)".Dumper(\@pp));}
   if (!@pp) {die("No package path comps for dotnot method resolution ($m)".Dumper(\@pp));}
   
   if (my $f = join('::', @pp)->can($mcp)) {$dotn2func{$m} = $f;return($f);}
   return(undef);
   
}
# URL2package based Service Class/Method resolver
sub methresolve {
   my ($r, $m) = @_;
   # Extract Package from URL:
   # get the global request object (requires PerlOptions +GlobalRequest)
   #my $r = Apache2::RequestUtil->request;
   # Thankfully both Apache2 and Nginx have this method
   my $uri = $r->uri();
   if (my $f = $urlm2func{$uri}->{$m}) {return($f);}
   my @pp = split(/\//, $uri);
   # Normalize components
   if (!$pp[0]) {shift(@pp);}
   if (!$pp[$#pp]) {pop(@pp);}
   # $ENV{'SCRIPT_NAME'}
   #my $dump = Dumper(\%ENV); # $dump
   if (!@pp || !$pp[0]) {
     die("No package comps for method resolution (uri=$uri)");
   }
   my $mcp = join('::', @pp);
   my $f = $mcp->can($m);
   if (!$f) {die("Tried meth '$m' from package: '$mcp'");return(undef);}
   # Cache to a URL-to-method map (NOT methname-to-func)
   $urlm2func{$uri}->{$m} = $f;
   return($f);
   #return("qmp"->can($m));
}

=head2 parse($jsontext)

Parse JSON-RPC Message and validate the essential parts of it. What is validated (per JSON-RPC spec):

=over 4

=item * method - must be non-empty

=item * params - presence (of key) - even null (value) is okay.

=item * id - JSON-RPC ID of message - must be present (format not strictly constrained)

=item * jsonrpc - JSON-RPC protocol version (must be '2.0')

=back

The particular format of "params" (Object/Array/scalar) or individual parameter
validation in case of most common case "Object" is not in the scope here.

=cut
# TODO: Allow application level constraining of "params" to certain type (e.g. HASH/Object)
sub parse { # JRPC::Msg::
   #my ($buffer) = @_;
   my $j = eval { decode_json($_[0]); }; # $buffer / $_[0]
   if ($@) {die("Error Parsing JSON(-32700): $@");}
   
   # Error on batch requests
   if (ref($j) eq 'ARRAY') {die("JSON-RPC Batch request not (yet) supported");}
   # These validation steps have a slight cost (3800 => 3600 for simple
   # method processing where relative framework overhead is major).
   # Allow to skip them with a config 
   #if (!$msgvalid) {
   return($j);
   #}
   #eval {
     # In order of importance method and params are necessary.
     if (!$j->{'method'}) {die("No 'method' found");}
     if (!exists($j->{'params'})) {die("No 'params' found");} # !(not) enough ?
     if ($msgvalid < 2) {return($j);}
     if (!$j->{'id'}) {die("No 'id' found");}
     if ($j->{'jsonrpc'} ne '2.0') {die("No jsonrpc version (2.0)found");}
     # Still validate envelope and param top level format
     
     # Additional params format constraint validation (fmtvalidator func ?)
     #if (my $fmt = $serv->{'pfmt'}) {}
   #};
   if ($@) {die("Invalid JSON-RPC Message (-32600): $@");}
   return($j);
}

#}; # END package JRPC;

=head2 respond_async($client, $url, $meth, $p, %opts);

After async processing, acknowledge the original client tier (or any URL) of the completion of the asynchronous part.
This method is experimental and the whole concept of using asynchronous processing at service is an unofficial extension
to standard JSON-RPC 2.0 protocol spec.

Parameters:

=over 4

=item * $client - Instance of JRPC::Client. If not provided, a new client will be instantiated here.

=item * $url - URL of the async callback - Must be provided

=item * $meth - JSON-RPC Method to callback to on the server (default: "oncomplete")

=item * $p - JSON-RPC "params" to send in completion acknowledgement (must be supplied, likely to be Object/Hash)

=back

If optional KW params in have param 'cb' set, it is used to process the response from callback service. The "result" of JSON-RPC response is passed to this callback.

Return "result" of response (likely to be Object/Hash).

=cut 

#Minor optimization for avoiding overhead of JRPC::Client instantiation in respond_async() (or during request) is to initialize it in the service package init() phase.

# TODO: Example of combination of init and a call to respond_async()
# package MyPack;
# ...
#our $client;
#sub init {
#   $client = JRPC::Client->new();
#}
#sub do_long_and_hard_work {
#   my ($p) = @_;
#   
#}
#TODO: Consider callback to handle specific response.
sub respond_async {
   my ($client, $url, $meth, $p, %c) = @_;
   #my $client = $opts{'client'}; # Allow passing client as optional ?
   # Create a full JRPC::Client instance if not passed.
   if (!$client) {$client = JRPC::Client->new();}
   if (!$url) {die("No Callback URL passed");}
   if (!$meth) {$meth = 'oncomplete';}
   if (!$p) {die("No Parameters passed");}
   # Always create a new request
   my $req = $client->new_request($url); # Client does not know URL, request does.
   if (!$req) {die("JSON-RPC Request not instantiated");}
   my $resp = $req->call($meth, $p, 'notify' => 1); # Need eval ?
   if (!$resp->is_success()) {die("HTTP Error: ".$resp->status_line());} # Status code ?
   #DEBUG:print($fh "Resp from '$url': ".$resp->content()."\n");
   # Server side may or may not care about this.
   # By default consider response as non-important as handling various specific responses here would
   # be hard.
   my $result = $resp->result();
   # Consider:Expect still a valid JSON response ? Parse it ?
   if (my $f = $c{'cb'}) {no strict 'refs';$f->($result);}
   return($result);
}

#setup_pkg_as_server($classname)
# Setup a Service package as independent, runnable server w.o. hard-wiring any
# code into a server package. Handy for testing a serice package.
# Loads HTTP::Server::Simple::CGI, JRPC::CGI, Attaches the "handle_request" callback method as request handler.
# After this setup all that remains to be done is to run the server (not done here).
# Complete example of making "MyServPkg" run.
#   use MyServPkg;
#   my $port = $ENV{'JSONRPC_SERVICE_PORT'} || 8080;
#   # Run in the same process
#   MyServPkg->new($port)->run();
sub setup_pkg_as_server {
   my ($class) = @_;
   # Bootstrapping boilerplate. We are (almost completely) n control of of $boot string here,
   # so eval is acceptable. Especially with validation of $class.
   if ($class !~ /^[\w:]+$/) {die("Class does not look right");} # No spaces
   my $boot =
   "use HTTP::Server::Simple::CGI;\npush(\@$class\:\:ISA, 'HTTP::Server::Simple::CGI');\nuse JRPC::CGI;\n";
   $boot .= "*$class\:\:handle_request = \\&JRPC::CGI::handle_simple_server_cgi;";
   #print(STDERR "$boot");
   eval("$boot");
}
1;
__END__

=head1 LIMITATIONS

JSON-RPC batch requests are not supported.

=head1 NOTES ON SERVICE PACKAGES

Service packages that implement the service are and should be completely independent of the
JRPC framework and its package namespaces.

=head1 FAQ

=head2 Should I inline my service package into my .pl file calling JRPC::CGI::handle_cgi($cgi) ?

Possibly, during the first prototyping minutes of the project. CGI is great for developing and prototyping,
but it has a low efficiency runtime for high-volume service. After getting your package running as a proof of concept,
place your package into external file named by package.

=head2 Does my service package with its service methods run in all JRPC::*(Apache2|Nginx|CGI) service runtimes ?

Assuming you paid attention to basic requirements of re-entrancy and long-lived persistent runtime - it will.
This means you can migrate a service package developed in plain old CGI runtime to run memory persistently in Nginx.
Anything running in long-lived runtime is prone to memory/variable corruption when sloppily designed, so approach these
solutions with the respect and care they deserve.

=head2 Using the "dot-notation" dispatching - can I have deep package paths ?

Yes. JSON-RPC methods, like "Shop.Product.Cart.add", will be translated to respective perl package "Shop::Product::Cart" and
a method add() within there. The need for particular dispathing method is autp-detected and things should "just work".
Choose your method notation strategy (read or review the section "DISPATCHING OF SERVICE REQUEST" for more info).

=head2 Is auto-loading of service packages supported ?

Not at the moment. The security reasons and potential for exploits are against this.
The service packages thus have to be loaded explicitly into the service runtime (by use ...
or require(...)). In future there could be an option to do auto-loading for development and
quick prototyping reasons.

=head2 Using JRPC::Apache2 - how do I load the service packages ?

Use either Apache PerlModule directive in httpd.conf:

   PerlModule Matrix

... or do the loading in a mod_perl conventional startup.pl file by including a loading directive
(Use the following to load startp.pl PerlPostConfigRequire /path/to/startup.pl):

   # startup.pl
   use Matrix;

The general hassle here is you typically have to have admin rights to author httpd.conf and startup.pl.
Per-directory ".htaccess" config is usually not allowed to do these config steps.

=head2 My Service package to use with JRPC::Apache2 is in an odd location and perl cannot find it in @INC. How do I enable Perl to find it?

Again you can add to @INC in httpd.conf or startup.pl. In httpd.conf, add:

   PerlSwitches "-I/odd/path/with/packages"

Or in startup.pl:

   use lib('/odd/path/with/packages')

A sustainable solution is to package your service package to a Perl standard (CPAN style) module package that
is easy to install to standard perl (@INC) library path locations (thus avoiding the PerlSwitches -I...
or use lib(...)).
However during development you will be likely using the above additions to perl library path (@INC).

=cut

