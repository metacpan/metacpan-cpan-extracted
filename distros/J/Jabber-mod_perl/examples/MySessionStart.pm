package MySessionStart;
use strict;
use Data::Dumper;
use Jabber::mod_perl qw(:constants);

sub init {

  print STDERR "Inside ".__PACKAGE__."::init() \n";

}

sub xwarn {
  warn "SM  : ".scalar localtime() ." : ", @_, "\n";
}

sub handler {
  
  my $class = shift; 
  my ($pkt, $chain, $instance) = @_; 
  xwarn "Inside ".__PACKAGE__."::handler()";
  xwarn "Packet is: ".$pkt->nad()->print(1);
  xwarn "chain is: $chain instance is: $instance";
  my $to = $pkt->to();
  my $from = $pkt->from();
  my $type = $pkt->type();
  xwarn "The to address is: ".$to;
  xwarn "The from address is: ".$from;
  xwarn "The type is: ".$type;
  return PASS;

}

1;
