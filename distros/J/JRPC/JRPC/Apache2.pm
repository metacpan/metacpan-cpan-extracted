
package JRPC::Apache2;
use JRPC;
use strict;
use warnings;
use Apache2::RequestRec ();
use Apache2::RequestIO ();
# qw(OK)
use Apache2::Const -compile => qw(:common); # 'OK', 'DECLINED'
use APR::Table ();
use JSON::XS;
use JRPC; # Import ... ?
*jdie = JRPC::createfault;
#use Storable (); # Would import store - do not want that.
# For Global Request (PerlOptions +GlobalRequest)
#use Apache2::RequestUtil;

=head1 NAME

JRPC::Apache2 - JSON-RPC Services in Apache2 / mod_perl runtime

=head1 DESCRIPTION

This package is a mod_perl JSON-RPC handler / dispatcher. It only contains the conventional mod_perl handler($r) callback method
(see mod_perl documentation for details: http://perl.apache.org/docs/2.0/user/config/config.html ).
Do not call the handler() method directly, but assign it to be used as a mod_perl handler (Servicpackage "Math" is used here for an example):

   # Load Service Package (for JRPC::Apache2 to use)
   PerlModule Math;
   # Assign directly to a URL Location / path by
   <Location /Math>
     SetHandler modperl
     PerlResponseHandler JRPC::Apache2
   </Location>

=cut
# Parse and handle JSON-RPC Request.
# reads POST body by $r->read($buffer, $len).
# if/else dispatching (of 3 meth) gives slight edge compared to
   # non-cached brute force method resolution (~770 vs. ~740)
   #if ($m eq 'add') {$resp = add($p);}
   #elsif ($m eq 'store') {$resp = store($p);}
   #elsif ($m eq 'multiply') {$resp = multiply($p);}

sub handler {
   my ($r) = @_;
   if ($r->method() ne 'POST') {return(Apache2::Const::DECLINED);} # 1 illegal
   my $hdrs_in = $r->headers_in();
   my $hdrs_out = $r->headers_out();
   my $buffer = '';my $len = 8000; # TODO: Grab _actual_ content-length
   my $cnt = $r->read($buffer, $len);
   #NA:my $hdlr = $r->handler(); # Returns String ("modperl")
   $r->content_type('text/plain');
   #####################################
   my $jresp = {'id' => $$, 'jsonrpc' => '2.0', }; # Set up dummy
   
   eval {
   if (!$cnt) {die("JSON-RPC Request body is Empty (-32700)");}
   # Parse Request
   my $j = eval { JRPC::parse($buffer); }; # 
   if ($@) {die("Error Parsing JSON-RPC Request: $@");}
   if (defined($JRPC::prelogger) && (ref($JRPC::prelogger) eq 'CODE')) {$JRPC::prelogger->($j);}
   my $p = $j->{'params'};
   my $m = $j->{'method'};
   $jresp->{'id'} = $j->{'id'};
   #my $res = {}; # Result
   my $f;my $mid = 0;
   if ($m =~ /\./) {$f =  JRPC::methresolve_dotnot($r, $m);$mid=1;}
   else {my $f =  JRPC::methresolve($r, $m);}
   if (!$f) {die("method '$m' not resolved (-32601) mid=$mid");}
   ##### reqinit
   #if (my $f = $pkg->can('reqinit')) {$f->($p, $j);}
   ##### Execute, store result
   my $res = eval { $f->($p); }; # Dispatch (catching any exceptions)
   if ($@) {die("Error in processing JRPC method '$m' (-32603): $@");}
   # Definite Success - serialize response ?
   $jresp->{'result'} = $res;
   ###### Respond
   #my $clen = $hdrs_in->get('content-length'); # Double verify read()
    # 'clen' => $clen, 'postread' => $cnt,
   # There could be blessed nodes in $res ('result' now) that do not serialize
   # well. Be ready to encounter exceptions here.
   DEBUG: $jresp->{'APAOK'} = Apache2::Const::OK;
   my $out = eval { encode_json($jresp); }; # Serialize as a separate step to know length
   if ($@) {die("Error Forming the response: $@");}
   ##########################
   $hdrs_out->{'content-length'} = length($out); # Raw assignment ?
   $r->print($out);
   };
   if ($@) {
      $r->print( JRPC::createfault($jresp, $@, 500) );
   }
   return Apache2::Const::OK;
}
#$r->err_headers_out->add('Set-Cookie' => $cookie);
#$r->print(encode_json($j));
1;

