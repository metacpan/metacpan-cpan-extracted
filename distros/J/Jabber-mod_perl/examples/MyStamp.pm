package MyStamp;
use strict;
use Data::Dumper;
use Jabber::mod_perl qw(:constants);

my $cnt = 0;

sub init {

  print STDERR "Inside ".__PACKAGE__."::init() \n";

}

sub xwarn {
  warn "SM  :  XWARN".scalar localtime() ." : ", @_, "\n";
}

sub handler {
  
  my $class = shift; 
  my ($pkt, $chain, $instance) = @_; 
  xwarn "Inside ".__PACKAGE__."::handler()";
  xwarn "Packet is: ".$pkt->nad()->print(0);
  xwarn "chain is: $chain instance is: $instance";
  my $to = $pkt->to();
  my $from = $pkt->from();
  my $type = $pkt->type();
  xwarn "The to address is: ".$to;
  xwarn "The from address is: ".$from;
  xwarn "The type is: ".$type;
  my $nad = $pkt->nad();
  my @attrs = ();
  foreach my $attr ( $nad->attrs(1) ){
    push(@attrs, [$nad->nad_attr_name($attr), $nad->nad_attr_val($attr)]);
  }
  xwarn "ELEMENT 1 (".$nad->nad_elem_name(1).") ATTRS: ".Dumper(\@attrs);
  return PASS unless $type eq "message";;
  my $el = $nad->find_elem(1,-1,"body",1);
  my $data = $nad->nad_cdata( $el );
  xwarn "Body element is: $el - $data";
  my $ns = $nad->find_scoped_namespace("http://jabber.org/protocol/xhtml-im","");
  xwarn "namespace is: $ns";
  xwarn "NAMESPACES: ".Dumper($nad->list_namespaces());
  my $elhtml = $nad->find_elem(1,$ns,"html",1) if $ns;
  xwarn "XHTML HTML element is: $elhtml";
  my $elx = $nad->find_elem($elhtml,-1,"body",1) if $elhtml;
  xwarn "BODY HTML element (no namespace) is: $elx";
  my $datax = $nad->nad_cdata( $elx ) if $elx;
  xwarn "Body xhtml element is: $elhtml/$elx - $datax" if $elx;
  #$nad->append_cdata_head($el, "some data or other");
  $nad->replace_cdata_head($el, "beginning... ($data/$el) ...some data or other") if $el > 0;
  $nad->replace_cdata_head($elx, "beginning... ($datax) ...some data or other") if $elx;

  # accumulate stats
  $cnt++;
  unless ($cnt%20) {
    # message the stats every 20 times
    xwarn "CREATING STATS MESSAGE";
    my $stats = $pkt->create("message", "", "piers\@badger.local.net", "piers\@badger.local.net");
    my $mn = $stats->nad;
    $mn->insert_elem(1, "", "subject", "Stats Message");
    $mn->insert_elem(1, "", "body", "We have processed ($cnt) messages.");
    $stats->router;
  }

  return PASS;
  
}

1;
