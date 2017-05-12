use strict;
use Jabber::Connection;
use Jabber::NodeFactory;
use Jabber::NS qw(:all);

my $NAME    = 'Test Component';
my $ID      = 'comp.localhost';
my $VERSION = '0.1';

my $c = new Jabber::Connection(
  server    => 'localhost:9999',
  localname => $ID,
  ns        => NS_ACCEPT,
  log       => 1,
  debug     => 1,
);

unless ($c->connect()) { die "oops: ".$c->lastError; }

debug("registering IQ handlers");
$c->register_handler('iq',\&iq_version);
$c->register_handler('iq',\&iq_notimpl);

debug("registering beat");
$c->register_beat(20, \&beep);

debug("authenticating");
$c->auth('secret');

debug("starting loop");
$c->start;

debug("cleaning up");
$c->disconnect;

sub beep {

  debug("beep!");

}


sub iq_version {

  my $node = shift;
  debug("[iq_version]");
  return unless $node->attr('type') eq IQ_GET 
         and my $query = $node->getTag('', NS_VERSION);
  debug("--> version request");
  $node = toFrom($node);
  $node->attr('type', IQ_RESULT);

  $query->insertTag('name')->data($NAME);
  $query->insertTag('version')->data($VERSION);
  $query->insertTag('os')->data(`uname -sr`);

  $c->send($node);

  return r_HANDLED;

}


sub iq_notimpl {

  my $node = shift;
  $node = toFrom($node);
  $node->attr('type', IQ_ERROR);
  my $error = $node->insertTag('error');
  $error->attr('code', '501');
  $error->data('Not Implemented');
  $c->send($node);

  return r_HANDLED;

}


sub toFrom {
  my $node = shift;
  my $to = $node->attr('to');
  $node->attr('to', $node->attr('from'));
  $node->attr('from', $to);
  return $node; 
}


sub debug {

  print STDERR "debug: ", @_, "\n";

}

