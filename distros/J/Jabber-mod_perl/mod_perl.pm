package Jabber::mod_perl;
use vars qw($VERSION @ISA);
$VERSION = '0.15';

use strict;
use vars q/$DEBUG/;
$DEBUG = 1;

use Cwd qw(abs_path);
use Jabber::Reload;


use Data::Dumper;



=pod

=head1 NAME

Jabber::mod_perl - Perl handlers for jabberd

=head1 DESCRIPTION 

Jabber::mod_perl is an embedded Perl interpreter in the jabberd2 sm ( session manager ).
mod_perl is the name of the handler that is registered in the sm, and is activated in the usual 
way ia the sm.xml config file - for example:
 ...
   <modules>
   ...
    <!-- pkt-sm receives packets from the router that are addressed directly to the sm host (no user) -->
    <chain id='pkt-sm'>
      <module>iq-last</module>      <!-- return the server uptime -->
      <module>iq-time</module>      <!-- return the current server time -->
      <module arg='Some::Other::Handler1'>mod_perl</module>     <!-- mod_perl handler -->
      <module>iq-version</module>   <!-- return the server name and version -->
      <module>echo</module>         <!-- echo messages sent to /echo -->
      <module arg='Some::Handler1 MyEcho'>mod_perl</module>     <!-- mod_perl handler -->
    </chain>
    ...
   </modules>
 ...

The list of Module chains that are currently supported are:
    * sess-start
    * sess-end
    * in-sess
    * out-sess
    * in-router
    * out-router
    * pkt-sm
    * pkt-user
    * pkt-router
 

next - other information that a module author wished to pass to a registered handler at
initialisation could be placed inside sm.xml file, as the whole nad representing this
is passed in when the handlers init() function is called.

  e.g.
  ..
  </modules>

  <mod_perl>
    <handler level='annoying'>MyEcho</handler>
    ....
  </mod_perl>

Order that modules are registered in is important, as this is the order of execution.

Each perl module can optionally have an init() method, and must have a handler() method.
The init() method is called when the mod_perl module is initialised.  
The handler is called for each packet that it is registered for ( as per the module 
processing chain described above ).


Additionally, Jabber::mod_perl is available as a separate component building framework built
into jadperl.  jadperl enables you to create your own components in Perl, using a multiple,
stacked handler environment, that is based on NADs, and sx (giving you SSL, and SASL etc.).

To activate jadperl you first need to create a configuration file - see the example: 
examples/jp.xml that comes with this distribution.
This can be launched like so:

export PERL5LIB=path/to/mod_perl/examples
/path/to/jabberd/bin/jadperl -c /path/to/configfile/jp.xml -D > /path/to/jabberd/jp.log 3>&1 &



=head2 Callback Handlers

=head3 init()

called with:
init(<nad of the sm.xml config>, <chain handler is registered in>, <instance number within a chain>);

The first parameter is the config nad of the session manager (from sm.xml).  This is a Jabber::NADs
object.
The second parameter is the chain that the handler has been registered in.
Third parameter is the instance number within the chain that the handler has been registered (enables 
module author to determine what order a handler is called in if it has been registered more than
once in a chain).

With this it should be possible to store any startup configuration for a handler in the <mod_perl/> 
element of the config, and use this to prep the handlers.

=head3 handler()

called with:
handler(<current packet in the sm>, <chain handler is registered in>, <instance number within a chain>);
The first parameter passed to a handler is the current packet that is passing through the session manager.
This is a Jabber::pkt object.
The second and third parameters are as for the init() function.

A handler must import the mod_perl constants by declaring them:
use Jabber::mod_perl qw(:constants);
and the handler must return either HANDLED or PASS -
 
  return HANDLED;

or 

  return PASS;

The first handler in the chain to return HANDLED short circuits the chain and tells the session manager
that the packet has been handled.
If you want successive modules to handle a packet then you must ensure that they all return PASS until the
final module is called (which would then return HANDLED );

=head2 Example

This example is a packet echo handler.

  package MyEcho;
  use strict;
  use Jabber::mod_perl qw(:constants);

  sub init {
    warn "Im initialising\n";
  }

  sub handler {
  
    my $class = shift; 
    my ($pkt, $chain, $instance) = @_;

    my $to = $pkt->to();
    return PASS unless $to =~ /^localhost\/mod_perl/;

    my $from = $pkt->from();
    warn "The to address is: ".$to."\n";
    warn "The from address is: ".$from."\n";
    my $newpkt = $pkt->dup($from, $to);
    $newpkt->router();
    return HANDLED;

  }
  1;


=head1 Jabber::Reload

Jabber::Reload is a built set of functions that test for changes in the
registered handler modules.  each handler that loads successfully is
registered and a base line file timestamp is taken.  Each time the handler
is to be executed the timestamp is checked, and if the module is changed it is 
reloaded into the interpreter, and the init() function is called again.
See Jabber::Reload for more details.


=head1 CONSTANTS 

=head2 HANDLED

return HANDLED to stop the entire sm chain handling for this pkt - use 
this value when you have processed a pkt on behalf of the sm.

=head2 PASS

return PASS when you want the Jabber::mod_perl, and the sm to carry on
processing the current pkt.

=head2 MESSAGE, PRESENCE, IQ

use these constants to check the pkt type of $pkt->type() (Jabber::pkt)

=head2 SESS_START, SESS_END, OUT_SESS, OUT_ROUTER, IN_SESS, IN_ROUTER, PKT_SM, PKT_USER, PKT_ROUTER JADPERL_PKT

use these constants to determine which processing chain the handler is in.

JADPERL_PKT is the packet chain for all packets processed by jadperl.


=head1 VERSION

very new

=head1 AUTHOR

Piers Harding - piers@cpan.org

=head1 SEE ALSO

jabberd and the session manager sm.

=head1 COPYRIGHT

Copyright (c) 2002, Piers Harding. All Rights Reserved.
This module is free software. It may be used, redistributed
and/or modified under the same terms as Perl itself.


=cut


use constant HANDLED => 1;
use constant PASS => 2;
use constant MESSAGE => "message";
use constant PRESENCE => "presence";
use constant IQ => "iq";
use constant SESS_START => "SESS_START";
use constant SESS_END => "SESS_END";
use constant OUT_SESS => "OUT_SESS";
use constant OUT_ROUTER => "OUT_ROUTER";
use constant IN_SESS => "IN_SESS";
use constant IN_ROUTER => "IN_ROUTER";
use constant PKT_SM => "PKT_SM";
use constant PKT_USER => "PKT_USER";
use constant PKT_ROUTER => "PKT_ROUTER";
use constant JADPERL_PKT => "JADPERL_PKT";

my @export_ok = qw ( HANDLED PASS 
                     MESSAGE PRESENCE IQ 
                     SESS_START SESS_END 
                     IN_SESS IN_ROUTER 
                     OUT_SESS OUT_ROUTER 
                     PKT_SM PKT_USER PKT_ROUTER
                     JADPERL_PKT );

sub import {

  my $class = shift;
  return unless shift eq ':constants';
  my ( $caller ) = caller;
  no strict 'refs';
  foreach my $const ( @export_ok ){
    *{"${caller}::${const}"} = \*{$const};
  }


}


my $mod_perl_handlers = {};
my $jadperl_running = 0;

sub initialise {

  my ( $nad, $instance, $chain, $handlers, @rest ) = @_;

  debug(__PACKAGE__."::initialise: initialising all handlers\n");
  debug("intialise: chain $chain instance $instance handlers $handlers - rest: ".join("/",@rest)." - config is: ".$nad->print(0));

  # if this is jadperl - realign the data
  if (@rest){
    $instance = $handlers;
    $handlers = join(" ", @rest);
    $jadperl_running = 1;
  }
  
  foreach my $handler (split(/\s+/,$handlers)){
    eval "use $handler;";
    if ($@){
      debug("Handler: $handler - did not load: $@");
    } else {
      # register for reloading
      Jabber::Reload::register($handler);
     
      # call init of handler
      if ($handler->can("init")){
        debug("$handler can do init ...");
        eval { $handler->init($nad, $chain, $instance); };
        if ($@){
          debug("onPacket::init() - call failed - $@");
        } else {
          debug("onPacket::init() - initialised $handler");
        }
      } else {
        debug("$handler cant do init ...");
      }

      # store away the handler
      if ($jadperl_running){
        push(@{$mod_perl_handlers->{$chain}},
               { 'name' => $handler, 'config' => $nad });
      } else {
        push(@{$mod_perl_handlers->{$chain}->{$instance}},
               { 'name' => $handler, 'config' => $nad });
      }
    }
  }
  debug("Handlers loaded...".Dumper($mod_perl_handlers));
  return 1;

}


sub onPacket{

  my ( $pkt, $instance, $chain, $handlers ) = @_;

  debug("onPacket: chain $chain instance $instance handlers $handlers");

  if ($jadperl_running){
    return PASS unless exists $mod_perl_handlers->{$chain};
  } else {
    return PASS unless exists $mod_perl_handlers->{$chain}
                   &&  exists $mod_perl_handlers->{$chain}->{$instance};
  }

  my $handlers = $jadperl_running ?
        $mod_perl_handlers->{$chain} : $mod_perl_handlers->{$chain}->{$instance};

  my $result = PASS;

  debug("Handlers are: ".Dumper($handlers));

  
  foreach my $handler ( @{$handlers} ){

    debug("onPacket: processing handler - ".$handler->{'name'});
    # check for reload
    if (Jabber::Reload::reload($handler->{'name'}) ){
      # call init of handler to reinitialise
      if ($handler->{'name'}->can("init")){
        eval { $handler->{'name'}->init($handler->{'config'}, $chain, $instance); };
        if ($@){
          debug("onPacket::init() - call failed - $@");
        } else {
          debug("onPacket::init() - initialised ".$handler->{'name'});
        }
      }
    }

    # execute the handlers and see what they did
    eval { $result = $handler->{'name'}->handler( $pkt, $chain, $instance ); };
    if ($@){
      debug("onPacket::handler() - call failed - $@");
    } else {
      debug("onPacket::handler() - executed ".$handler->{'name'}." - result: $result");
    }
    last if $result == HANDLED;
  }
  return $result;

}


sub debug {

  return unless $DEBUG;
  print  STDERR scalar localtime().": ", @_, "\n";

}

1;
