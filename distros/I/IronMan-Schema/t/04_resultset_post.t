use warnings;
use Test::More tests => 3;


# Test the IronMan::Schema::ResultSet::Post local functions.

use IronMan::Schema;
use DateTime;

my $dir = "t/var/";
my $file = "test.db";

my $schema = IronMan::Schema->connect("dbi:SQLite:$dir$file");

# Create a DateTime for right now.
my $dt = DateTime->now;

my $posts;

# Get posts_for_day
ok($posts = $schema->resultset('Post')->posts_for_day($dt));

# Get posts_for_month
ok($posts = $schema->resultset('Post')->posts_for_month($dt));

# Calculate the DateTime for start and end of our DateTime created above
my $month_start = $dt->clone()->truncate( 'to' => 'month');
my $month_end = $month_start->clone()->add( 'months' => 1 )->subtract( 'seconds' => 1 );

# Get posts_for_daterange
ok($posts = $schema->resultset('Post')->posts_for_daterange($month_start, $month_end));

