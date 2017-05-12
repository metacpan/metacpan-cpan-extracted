package MyEcho;
use strict;
use Data::Dumper;
use Jabber::mod_perl qw(:constants);

sub init {

  print STDERR "Inside ".__PACKAGE__."::init() \n";

}

sub handler {
  
  my $class = shift; 
  my ($pkt, $chain, $instance) = @_; 
  warn "Inside ".__PACKAGE__."::handler()  \n";
  warn "Packet is: ".$pkt->nad()->print(1)."\n";
  warn "chain is: $chain instance is: $instance\n";

  return PASS unless $chain eq PKT_SM || $chain eq JADPERL_PKT;

  my $to = $pkt->to();
  my $from = $pkt->from();
  my $type = $pkt->type();
  warn "The to address is: ".$to."\n";
  warn "The from address is: ".$from."\n";
  warn "The type is: ".$type."\n";
  my $nad = $pkt->nad();
  warn "Packet is: ".$nad->print(1)."\n";

  return PASS unless $type eq MESSAGE;

  return PASS unless $to =~ /^(localhost\/mod_perl|jpcomp)/;

  my $el = $nad->find_elem(1,-1,"body",1);
  warn "Element is: $el\n";
  return PASS unless $el > 0;

  $el = $nad->insert_elem($el, -1, "blah", "some data or other");

  my $newpkt = $pkt->dup($from, $to);
  $pkt->free();

  $newpkt->router();

  return HANDLED;

}

1;
