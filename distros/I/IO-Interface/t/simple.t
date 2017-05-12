# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

use lib './blib/lib','./blib/arch';

use Test::More tests=>11;

BEGIN { use_ok('IO::Interface::Simple') }

ok(!IO::Interface::Simple->new('foo23'),"returns undef for invalid interface name");
ok(!IO::Interface::Simple->new_from_address('18'),"returns undef for invalid address");
ok(!IO::Interface::Simple->new_from_index(-1),"returns undef for invalid index");

my @if = IO::Interface::Simple->interfaces;
ok(@if>0, 'fetch interface list');

# find loopback interface
my $loopback;
foreach (@if) {
  next unless $_->is_running;
  $loopback ||= $_ if $_->is_loopback;
}

ok($loopback,"loopback device");
ok($loopback->address eq '127.0.0.1','loopback address');
ok($loopback->netmask eq '255.0.0.0','loopback netmask');

SKIP: {
  my $index = $loopback->index;
  skip ('index not implemented on this platform',3) unless defined $index;

  ok(defined $index,'loopback index');

  my $if    = IO::Interface::Simple->new_from_index($index);
  ok($if eq $loopback,"new_from_index()");

  $if       = IO::Interface::Simple->new_from_address('127.0.0.1');
  ok($if eq $loopback,"new_from_address()");
}


