package JRPC::CGI;
# Leave this up to the implementor ?
#use CGI;
#use CGI::Carp qw/fatalsToBrowser warningsToBrowser/;
use JSON::XS;
use JRPC;
use strict;
use warnings;
use Scalar::Util ('reftype'); # Check base types

=head1 NAME

JRPC::CGI - JSON-RPC 2.0 Processing for CGI and HTTP::Server::Simple::CGI

=head1 DESCRIPTION

This package provides JSON-RPC 2.0 services processor for 2 runtimes based on:

=over 4

=item * CGI (CGI.pm) Plain old CGI scripting (or mod_perl ModPerl::Registry mode)

=item * HTTP::Server::Simple::CGI - a fast and lightweight runtime with a Perl embedded httpd (web server) module.

=back

HTTP::Server::Simple::CGI is especially interesting for doing distributed computation over the http.

=head1 METHODS

Because of the rudimentary nature of CGI (in both good and bad), the JRPC::CGI::handle_cgi($cgi) is to be called explicitly in code
(as CGI is not hosted by sophisticated server).

The service method JRPC::CGI::handle_simple_server_cgi($server, $cgi); for HTTP::Server::Simple::CGI can be aliased to local package's handle_request
method, which is the request handling method for HTTP::Server::Simple framework (similar to mod_perl's and Nginx's handler($r) method).

=cut

our $mimetype = 'text/plain';
# Plug for uri-method transparency
# Do NOT use CGI::url method for uri purpose !
# Keep this anywhere that may use CGI request object
sub CGI::uri {return $_[0]->script_name();}
# JSON RPC Response ID for malformed requests.
our $naid = 666666666;

=head2 JRPC::CGI::handle_cgi($cgi)

Traditional CGI Handler for JRPC. Example CGI wrapper:

   #!/usr/bin/perl
   use CGI;
   use CGI::Carp qw/fatalsToBrowser warningsToBrowser/;
   use JRPC::CGI;
   use SvcTest; # Load Service package
   my $cgi = CGI->new();
   # Process request. Reports all errors to Client as a JSON-RPC error (fault) response.
   JRPC::CGI::handle_cgi($cgi);
   exit(0);
   
   # This "Service Package" could (and should) be in a separate file (SvcTest.pm).
   # It will be called back by JRPC.
   package SvcTest;
   use Scalar::Util ('reftype');
   # Simpliest possible service:
   # - reflect/echo 'params' (of request) to 'result' (of response)
   # - Framework will take care of request parsing and response serialization
   # - On validation errors, Framework will turn a Perl exception to a JSON-RPC fault.
   # Call this by: ..., "method": "Test.echo", ...
   sub echo {
      my ($p, $jrpc) = @_;
      # Validate, require $p to be HASH (ref).
      # Framework will convert exceptions to JSON-RPC Fault
      if (reftype($p) ne 'HASH') {die("param was not found to be a JSON Object");}
      return($p);
   }
   1;


=cut

# Could do Storable::dclone($p) to be on paranoid side

sub handle_cgi {
   my ($cgi) = @_;
   
   # Early mime output
   # TODO: Also Include length ...must be later
   # DEBUG: print("Extra: Math-$Math::VERSION\r\n");
   print("Content-type: $mimetype\r\n"); # .termheaders()
   my $jresp = {'id' => $naid, 'jsonrpc' => '2.0', }; # Set up dummy
   my $buffer = $cgi->param('POSTDATA'); # POST Body
   my $j;
   # EVAL ...
   eval {
   if (!$buffer) {die("JSON-RPC Request body is Empty (-32700)");}
   #my $req = eval { JSON::XS::decode_json($jstext); };
   $j = eval { JRPC::parse($buffer); };
   if ($@) {die("Error Parsing Request: $@");}
   if (defined($JRPC::prelogger) && (ref($JRPC::prelogger) eq 'CODE')) {$JRPC::prelogger->($j);}
   my $p = $j->{'params'};
   my $m = $j->{'method'};
   $jresp->{'id'} = $j->{'id'};
   my $f; # Below: Support both plain-method and dot-notation dispatching.
   my $mid = 0;
   # TODO: index($m, '.') > 0 # Faster than regex ?
   if ($m =~ /\./) {$f =  JRPC::methresolve_dotnot($cgi, $m);$mid=1;}
   else {$f =  JRPC::methresolve($cgi, $m);} #
   if (!$f) {die("method '$m' not resolved (-32601) mid=$mid");}
   ##### reqinit
   #if (my $f = $pkg->can('reqinit')) {$f->($p, $j);}
   # Execute
   my $res = eval { $f->($p); }; # Dispatch (catching any exceptions)
   if ($@) {die("Error in processing JSON-RPC method '$m' (-32603): $@");}
   # Definite Success - serialize response ?
   $jresp->{'result'} = $res;
   # Output
   my $out = eval { encode_json($jresp); }; # Serialize as a separate step to know length
   if ($@) {die("Error Forming the JSON-RPC result response: $@");}
   # $hdrs_out->{'content-length'} = length($out); # TODO:
   
   # Late headers ?
   print(termheaders(length($out)).$out);
   }; # End processing eval
   # Formulate a fault
   # Problem: any output here gets duplicated (literal or function generated).
   # Info: Service package was missing use strict; use warnings;. Was suing wrong var for forked child PID
   # $pid instead of $cpid, so was getting wrong info for fork() success. fork() process duplication
   # seemed to cause output duplication as STDIN,STDOUT were not yet successfully closed.
   # handle async processing by fork() with care !
   if ($@) {
      my $fault = JRPC::createfault($j, $@, 500);
      #DEBUG:open(my $fh, ">>", "/tmp/jrpc.$$.out");
      #DEBUG:print($fh "\n=====\n$fault\n=====\n");
      #DEBUG:close($fh);
      print(termheaders(length($fault)).$fault);
      #TEST:print("{}");
   }
   #return(0);
}

# Helper sub to terminate HTTP headers with content length passed/
sub termheaders {
   if ($_[0]) {return("Content-length: $_[0]\r\n\r\n");}
   return "\r\n";
   #"";
}
# TODO: Overload for both signatures:
   # - ($cgi)
   # - (HTTP::Server::Simple::CGI, $CGI)

=head2 JRPC::CGI::handle_simple_server_cgi($server, $cgi);

 Wrapper for intercepting a request to HTTP::Server::Simple::CGI.
 Alias this as a handle_request() in your package implementing
 HTTP::Server::Simple::CGI. Example:

   #!/usr/bin/perl
   {
   package MyJRPC;
   use HTTP::Server::Simple::CGI;
   use base 'HTTP::Server::Simple::CGI';
   # Reuse handle_simple_server_cgi, assign as local alias.
   *handle_request = \&JRPC::CGI::handle_simple_server_cgi;
   }
   my $port = $ENV{'HTTP_SIMPLE_PORT'} || 8080;
   my $pid = MyWebServer->new($port);
   #my $pid = MyWebServer->new($port)->background();
   
   print "Use 'kill $pid' to stop server (on port $port).\n";

=head1 RUNNING SERVER IN THREAD

To be able to run server in thread and to be able to terminate the thread, use the following idiom:

   # Server thread as anonymous sub. Pass port to run at.
   my $runmyserver = sub {
     my ($port) = @_;
     # Use signaling to kill thread
     $SIG{'KILL'} = sub { threads->exit(); };
     # Run in the same process, NOT spawning a sub process.
     MyServer->new($port)->run();
   };
   
   my $thr = threads->create($runmyserver, $port);
   # ...
   # Much later ... terminate server as no more needed.
   $thr->kill('KILL')->detach();
   # This main thread should continue / survive beyond this point ...

=head1 HINTS

JSON-RPC is not a domain for obsessed print(); debugging folks. Printing to STDOUT messes up the JSON-RPC response output.
The returned data structure gets automatically converted to a successful JSON-RPC Response (data goes into 'result' member).
Any fatal errors thrown as Perl exceptions get automatically converted to a valid JSON-RPC exception / fault
(member 'error', and optionally to logs).
Any diagnostic messaging goes to response or logs (or both), NOT STDOUT.

=head1 TODO

=over 4

=item * Private package (file) for ServerSimple (with direct default handler handle_request())?

=item * In private package use HTTP::Server::Simple::CGI (and inherit from it)

=back

=cut
#use JRPC::CGI; # To have the uri() method
# NOTE REQUEST_URI (or PATH_INFO) contains
our $haveuri = 0;
# For testing purposes ONLY.
# Note: These should reside in context of serv. pkg. or $server (see below).
# Need a nice accessor for this: Pkg->dieaftercnt(3) (Inherit)
our $dieaftercnt = 0;
our $reqcnt = 0;
# sub CGI::uri {return $ENV{'REQUEST_URI'};}
sub handle_simple_server_cgi {
   my ($server, $cgi) = @_;
   if (!$haveuri) {
      #no strict ('subs');
      eval("sub CGI::uri {return \$ENV{'REQUEST_URI'};}");
      $haveuri++;
   }
   
   if ($cgi->request_method() ne 'POST') {
      print("HTTP/1.0 500 Must Send a POST\r\nContent-type: text/plain\r\n\r\nNeed to POST-the-JSON");return;
   }
   # Too early to say ? It's okay, the message (result/error) will tell the outcome.
   # We trust in server catching every exception and turning it into error.
   print("HTTP/1.0 200 OK\r\n");
   # Use Standard handle_cgi() for the rest
   handle_cgi($cgi);
   # TODO: Move this to be package specific
   #$reqcnt++;
   #DEBUG:print(STDERR "CNT: $reqcnt, vs. $dieaftercnt\n");
   #threads->exit(); # This works
   #print("PASSED\n");
   #if ($dieaftercnt && ($reqcnt >= $dieaftercnt)) {
   #   #sleep(3);
   #   my $thr;
   #   my $can = threads->can('exit');
   #   DEBUG:print(STDERR "Count full, ready to term (threads: $threads::VERSION) $can\n");
   #   # TODO: Initial Problem - thread does not exit like wanted. It _does_ exit, but join() does not happen!!!
   #   $thr = threads->self();
   #   #$thr->exit();
   #   threads->exit();
   #   print(STDERR "Passed threads->exit() thr=$thr\n"); #  
   #}
}
1;
