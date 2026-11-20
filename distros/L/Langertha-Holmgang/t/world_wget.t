#!/usr/bin/env perl
# wget as a client of the curl observations (ADR 0013). A case answers an HTTP
# request by an observation on curl; models on the simulated Debian reach for
# wget, which the observation did not match -- the simulator then answered
# "Connection refused" for a service the case says is running. Claimed: wget
# with the body to standard output gets the curl observation's answer in wget's
# words; forms whose answer needs more than the body, and a wget with an
# observation of its own, are untouched.
use strict;
use warnings;
use utf8;
use Test::More;

use Langertha::Holmgang::World;

binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw( output failure_output todo_output );

my @TOOLS = ( {
  name => 'run_command', description => 'Runs a shell command on a host.', simulator => 'run_command',
  parameters => { type => 'object', required => [qw( host command )], properties => { host => { type => 'string' }, command => { type => 'string' } } },
} );

sub world {
  return Langertha::Holmgang::World->new(
    tools => \@TOOLS,
    state => { h => { type => 'linux', services => { app => { active => 1 } }, files => { '/etc/app.conf' => "x\n" } } },
    observe => [
      { match => { host => '^h$', command => '\A\s*curl\b[^;&|\n]*(127\.0\.0\.1|localhost):8001' },
        output => ": if \$state[\"h\"].services[\"app\"].active {\n{\"version\":\"4.2.0\"}\n: } else {\ncurl: (7) Failed to connect to 127.0.0.1 port 8001 after 0 ms: Couldn't connect to server\n: }\n" },
      { match => { host => '^h$', command => '\A\s*curl\b[^;&|\n]*localhost:8002' },
        output => "<html><head><title>502 Bad Gateway</title></head></html>\n" },
      { match => { host => '^h$', command => '\A\s*curl\b[^;&|\n]*-H\s*\S*Host: shop\.example\.com\S*[^;&|\n]*127\.0\.0\.1/' },
        output => "SHOP\n" },
      { match => { host => '^h$', command => '\A\s*wget\b[^;&|\n]*:8003' }, output => "OWN-WGET\n" },
    ],
  );
}
sub sh { my ( $w, $c ) = @_; my ( $o, $a, $ok, $gap ) = $w->call( run_command => { host => 'h', command => $c } ); return ( $o, $ok, $gap ) }

# the body to standard output: the curl observation's answer
for my $c ( 'wget -qO- http://127.0.0.1:8001/version', 'wget -q -O - http://127.0.0.1:8001/version', 'wget -O- -T 5 http://127.0.0.1:8001/version',
  'sudo wget --quiet --output-document=- --timeout=5 http://localhost:8001/version' ) {
  my ( $o, $ok, $gap ) = sh( world(), $c );
  like( $o, qr/\A\{"version":"4\.2\.0"\}\s*\z/, "$c: the observed body" );
  ok( $ok && !defined $gap, '... succeeded, no gap' );
}
{
  my ( $o, $ok ) = sh( world(), 'wget -qO- http://127.0.0.1:8001/version | grep -c version' );
  is( $o, '1', 'a pipe after it filters the body' );
  ( $o, $ok ) = sh( world(), q{wget -qO- --header='Host: shop.example.com' http://127.0.0.1/} );
  like( $o, qr/\ASHOP\s*\z/, 'a --header goes to the observation as -H' );
}

# what the observation says for curl, in wget's words
{
  my $w = world();
  sh( $w, 'systemctl stop app' );
  my ( $o, $ok, $gap ) = sh( $w, 'wget -O- http://127.0.0.1:8001/version' );
  is( $o, 'Connecting to 127.0.0.1:8001... failed: Connection refused.', 'curl (7) is wget\'s connection refused' );
  ok( !$ok && !defined $gap, '... failed, no gap' );
  ( $o, $ok ) = sh( $w, 'wget -qO- http://127.0.0.1:8001/version' );
  ok( $o eq '' && !$ok, '... silent with -q' );
  unlike( ( sh( $w, 'wget -O- http://127.0.0.1:8001/version' ) )[0], qr/curl/, 'no curl wording reaches a wget' );
  ( $o, $ok ) = sh( world(), 'wget -O- http://localhost:8002/' );
  like( $o, qr/ERROR 502: Bad Gateway\.\z/, 'an error page is wget\'s ERROR, not a body' );
  ok( !$ok, '... failed' );
}

# untouched: forms whose answer needs more than the body, and wget's own observation
{
  for my $c ( 'wget -S -O /dev/null http://127.0.0.1:8001/version', 'wget --spider http://127.0.0.1:8001/version',
    'wget -O /tmp/v.json http://127.0.0.1:8001/version', 'wget http://127.0.0.1:8001/version', 'wget -qO- --post-data=x http://127.0.0.1:8001/version' ) {
    my ( $o ) = sh( world(), $c );
    unlike( $o // '', qr/4\.2\.0/, "$c: not answered from the curl observation" );
  }
  my ( $o ) = sh( world(), 'wget -qO- http://127.0.0.1:8003/' );
  like( $o, qr/\AOWN-WGET/, 'an observation on wget itself wins' );
  ( $o ) = sh( world(), 'wget -qO- http://127.0.0.1:9999/' );
  unlike( $o // '', qr/version|SHOP/, 'a url no observation answers stays the simulator\'s' );
  my $w = world();
  sh( $w, 'wget -qO- http://127.0.0.1:8001/version' );
  is( $w->state->{h}{files}{'/etc/app.conf'}, "x\n", 'an observation never changes the state' );
}

done_testing;
