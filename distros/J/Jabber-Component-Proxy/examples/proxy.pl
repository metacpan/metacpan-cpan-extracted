use strict;
use warnings;
use Jabber::Component::Proxy;

my $p = new Jabber::Component::Proxy(
  server => 'localhost:8888',
  identauth => 'confproxy.qmacro.dyndns.org:secret',
  realcomp  => 'conf.internal',
  rulefile  => 'access.xml',
);

$p->start;

