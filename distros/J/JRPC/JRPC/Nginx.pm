package JRPC::Nginx;
use JRPC;
use JSON::XS;
# require - to avoid symbol resolution problems ?
require nginx; # nginx / Nginx ?
use strict;
use warnings;

our $VERSION = "0.9";

# See Perldoc at the end...
sub handler {
   my ($r) = @_;
   no strict 'subs';
   # NGinx:
   if ($r->request_method() ne 'POST') {return DECLINED;}
   # NGinx $r->header_in(header)
   # Nginx: The body must be under
   #my $buffer = $r->request_body();
   # Nginx: $r->header_out('Content-type', 'text/plain');
   # OR:
   $r->send_http_header('text/plain');
   #my $hasbody = 
   $r->has_request_body(\&handle_2nd_stage);
   #####################
   return OK;
}
#=head2 handle_2nd_stage($r);
# Internal method to handle Nginx Asynchronous Post-request POST-Body stage.
#This encapsulates the 
#=cut
sub handle_2nd_stage {
   my ($r) = @_;
   my $jr = {'id' => $$, 'jsonrpc' => '2.0', };
   my $buffer = $r->request_body();
   
   eval {
   # Parse Request
   my $j = eval { JRPC::parse($buffer); };
   if ($@) {die("Error Parsing Request: $@");}
   if (defined($JRPC::prelogger) && (ref($JRPC::prelogger) eq 'CODE')) {$JRPC::prelogger->($j);}
   my $p = $j->{'params'};
   my $m = $j->{'method'};
   
   my $uri = $r->uri();
   #my $res = {}; # Result
   my $f = eval {JRPC::methresolve($r, $m);};
   if (!$f || $@) {die("method '$m' not resolved (-32601) URI: $uri: $@");}
   ##### reqinit
   #if (my $f = $pkg->can('reqinit')) {$f->($p, $j);}
   ##### Execute, store result
   my $res = eval { $f->($p); }; # Dispatch (catching any exceptions)
   if ($@) {die("Error in processing JRPC method '$m' (-32603): $@");}
   # Definite Success - serialize response ?
   $jr->{'result'} = $res;
   #my $clen = $hdrs_in->get('content-length'); # Double verify read()
    # 'clen' => $clen, 'postread' => $cnt,
   # There could be blessed nodes in $res ('result' now) that do not serialize
   # well. Be ready to encounter exceptions here.
   my $out = JSON::XS::encode_json($jr); # Serialize as a separate step to know length
   
   ################# Nginx Output Response ################
   $r->header_out('Content-length', length($out));
   $r->print($out);
   }; # eval for full processing
   if ($@) {
      $r->print( JRPC::createfault($jr, $@, 500) );
   }
   # Nginx:
   $r->rflush();
   no strict 'subs';
   return OK;
}

1;
__END__


=head1 NAME

JRPC::Nginx - JSON-RPC Services in Nginx runtime

=head1 SYNOPSIS

Nginx main config /etc/nginx/nginx.conf includes /etc/nginx/conf.d/*.conf.
Add a Perl config in /etc/nginx/conf.d/perl.conf (sometimes the name nginx-perl.conf is used):

    perl_modules  /home/theuser/src/miscapps/JRPC/examples;
    #perl_require  hello_nginx.pm;
    perl_require  SimpleMath.pm;

Assign the handler to a URL in your site config (in /etc/nginx/sites-available/)

   location /Math { perl JRPC::Nginx::handler; }

=head1 DESCRIPTION

JRPC::Nginx allows to host JSON-RPC 2.0 services in Nginx web server runtime similar to Apache2 / mod_perl (See JRPC::Apache2).
The main benefit of Nginx is its lightweight memory consumption, scalability for request volume (see various studies) and ultrafast request processing speed.

=head1 METHODS

=head2 handler($r)

JSON-RPC Handler / Dispatcher for Nginx.
This handler has to be assigned to a URL path location in the site configuration in /etc/nginx/sites-available/ (see SYNOPSIS section above).
It is not meant to be called explicitly.

For writing service packages and handler methods, see the rest of the JRPC documentation.

=head1 REFERENCES

=over 4

=item * For Nginx Perl API See: http://wiki.nginx.org/HttpPerlModule

=item * https://threatpost.com/debian-patches-holes-in-nginx-perl-module/103010

=back

Installation of Nginx on Debian (nginx-extras includes Perl module):

   sudo apt-get install nginx-extras nginx-doc

nginx-extras contains all the extra Nginx modules (contained in Nginx main codebase) statically linked in.

=cut

#Search the package manager repos of your distribution 
#Note: Weirdly ginx-extras is mutually exclusive with nginx and nginx-full

