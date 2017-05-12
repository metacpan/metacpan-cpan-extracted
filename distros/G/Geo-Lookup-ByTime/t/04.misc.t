use Test::More tests => 3;
use Geo::Lookup::ByTime;

package Point;

sub new {
    my $class = shift;
    my $self  = shift;
    return bless($self, $class);
}

sub latitude  { return $_[0]->{lat}; }
sub longitude { return $_[0]->{lon}; }
sub time      { return $_[0]->{time}; }

package main;

my $time   = time();
my $lookup = Geo::Lookup::ByTime->new();

my $p1 = new Point({ lat => 57,   lon => -2,   name => 'here',  time => $time++ });
my $p2 =           { lat => 57.9, lon => -2.5, name => 'there', time => $time++ };

$lookup->add_points($p1);
$lookup->add_points($p2);

my ($first, $last) = $lookup->time_range();
my ($s1, $r1, $d1) = $lookup->nearest($first);
is($r1 . '', $p1 . '', 'original object returned');
is_deeply($r1, $p1, 'fist object unchanged');
my ($s2, $r2, $d2) = $lookup->nearest($last);
is_deeply($r2, $p2, 'last object unchanged');
