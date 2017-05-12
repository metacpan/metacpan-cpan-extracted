use Test::More tests => 103;

BEGIN {
    use_ok('Geo::Lookup::ByTime');
}

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

my $init_time = time();
my $init_lat  = 54.0;
my $init_lon  = -2.0;

my ($time, $lat, $lon);

sub restart {
    ($time, $lat, $lon) = ($init_time, $init_lat, $init_lon);
}

# Iterator
sub iter {
    return if $lat >= 55.0;
    my $pt = {
        lat  => $lat,
        lon  => $lon,
        time => $time
    };
    $lat += 0.01;
    $lon += 0.02;
    $time--;
    return $pt;
}

restart();

my @p1 = reverse map { iter() } 1 .. 10;
my @p2 = map         { iter() } 1 .. 10;
my @p3 = map         { Point->new(iter()) } 1 .. 10;

my $lookup = Geo::Lookup::ByTime->new(@p1);

is_deeply($lookup->get_points(), \@p1, 'array to constructor');

# Add points by passing an array ref, an array and an iterator
$lookup->add_points(\@p3, @p2, \&iter);

restart();
my @pall = ();
while (my $pt = iter()) {
    unshift @pall, $pt;
}

my $pts = $lookup->get_points();
delete $_->{orig} for @{$pts};

is_deeply($pts, \@pall, 'added all points');

# Time ascends?

my $last_time = undef;
for (@{$pts}) {
    if (defined($last_time)) {
        ok($last_time < $_->{time}, 'time ascends');
    }
    $last_time = $_->{time};
}

