#!perl -w
use strict;
use Test::More tests => 2;

my $pkg = 'Device::Ericsson::AccessoryMenu';
use_ok( $pkg );
my $remote = $pkg->new;

isa_ok( $remote, $pkg );

$remote->menu( [
    'Remote' => [
        pause => sub { print "# paused\n" },
        Volume => [
            up   => sub { print "# vol +\n" },
            down => sub { print "# vol -\n" },
           ],
       ],
   ]);

$remote->port( bless {}, 'DummyPort' );

$remote->register_menu;

package DummyPort;
# enough of the Device::SerialPort api to do some testing
sub write {
    my ($self, $what) = @_;
    $what =~ s/\r$//;
    print "# wrote '$what'\n";
}

sub write_drain { }

sub read { ( 3, "OK\r" ) }

sub purge_all {}
