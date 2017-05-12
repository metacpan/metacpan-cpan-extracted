use strict;
use Jabber::Connection;
use Jabber::NodeFactory;
use Jabber::NS qw(:all);

my $nf = new Jabber::NodeFactory;

my $c = new Jabber::Connection(
  server => 'localhost',
  log    => 1,
);

$c->connect or die "oops: ".$c->lastError;
$c->register_handler('message', \&message);
$c->auth('a', 'pass', 'client');

my $m = $nf->newNode('message');
$m->insertTag('body')->data('hello');
$m->attr('to', 'dj@localhost');
$c->send($m);
$c->send('<presence/>');

my $iq = $nf->newNode('iq');
$iq->attr('type', IQ_GET);
$iq->attr('to', 'localhost');
$iq->insertTag('query', NS_TIME);
$c->send($iq);

$c->process(5);

$c->disconnect;


sub message {

  my $node = shift;
  print "Received --> ", $node->toStr, "\n";

}
