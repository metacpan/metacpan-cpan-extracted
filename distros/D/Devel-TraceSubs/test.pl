#!/usr/bin/perl -w
use strict;
use warnings;
use Test;
$|++;

BEGIN { plan tests => 18 }

package particle::quark;
sub up { print 'up', $/ }
sub down { @_ }

package electron;
sub gun { $_[0] ** 2 }

package main;

sub foo { particle::quark::up() }
sub ack{ 'in','out' }
our $charmed = 'electron::';
our @strange = qw/ particle::quark:: /;
our( $x, $y, $z, @ans);

# start tests
use Devel::TraceSubs 0.02;
ok(1);
ok( $Devel::TraceSubs::VERSION, '0.02' );

$x = new Devel::TraceSubs();
ok( $x, qr/^Devel::TraceSubs=HASH\(/ );

$y = Devel::TraceSubs->new( params => 1 );
ok( $y, qr/^Devel::TraceSubs=HASH\(/ );

$z = Devel::TraceSubs->new( logger => \&ack );

eval{ my $x = Devel::TraceSubs->new( verbose => 1, wrap => ['<!-- ', ' -->'] ) };
ok( $@, qr/ERROR: cannot use verbose mode with wrappers/ );

$x = Devel::TraceSubs->new( verbose => 0, pre => '>', post => '<',
  level => '~', params => 1, wrap => ['<!-- ', ' -->'] );

{
  # prevent warnings during test
  local *OLDERR;
  open(OLDERR, '>&STDERR') or die 'Cannot dup STDERR';
  close(STDERR);

  @ans = $x->trace( 'wave::' );
  ok( @ans, 0 ); # nonexistant package

  @ans = $x->trace( $x );
  ok( @ans, 0 ); # references not allowed

  @ans = $x->trace( 'electron' );
  ok( @ans, 0 ); # must provide trailing colons

  @ans = $x->trace( 'Devel::TraceSubs::' );
  ok( @ans, 0 ); # self not allowed

  @ans = $x->trace( *electron:: );
  ok( @ans, 0 ); # globs not allowed

  open(STDERR, '>&OLDERR') or die $!;
}

@ans = $x->trace( 'particle::quark::' );
ok( join('', sort @ans), 'particle::quark::downparticle::quark::up' );
ok( @ans, 2 );

@ans = $y->trace( $charmed );
ok( join('', sort @ans), 'electron::gun' );
ok( @ans, 1 );

@ans = $z->trace( @strange );
ok( join('', sort @ans), 'particle::quark::downparticle::quark::up' );
ok( @ans, 2 );

use Data::Dumper;
my $a = new Devel::TraceSubs();
{
  # prevent warnings during test
  local *OLDERR;
  open(OLDERR, '>&STDERR') or die 'Cannot dup STDERR';
  close(STDERR);

  @ans = $a->trace( 'Data::Dumper::' );

  open(STDERR, '>&OLDERR') or die $!;
}
ok( @ans, 0 );
ok( "@ans", '' );

# Results
my $tests = $Test::ntest - 1;
my $fail = @Test::FAILDETAIL;
my $ok = $tests - $fail;
print "\nCompleted $tests tests $ok/$tests OK, failed $fail/$tests\n";
printf "%3.1f%% of tests completed successfully, %3.1f%% failed\n\n" , 
  $ok*100/$tests, $fail*100/$tests;
print "Please email \$VERSION, OS and test numbers failed
to particle\@artfromthemachine.com so I can fix them.\n";
