use strict;
use warnings;
use Test::More tests => 2;

# Test the IronMan::Schema::ResultSet::Feed local functions.

use IronMan::Schema;

my $dir = "t/var/";
my $file = "test.db";

my $schema = IronMan::Schema->connect("dbi:SQLite:$dir$file");

my %feed = (
    url   => "http://www.google.com/",
    title => "Google homepage",
    email => 'google@example.com',
);

# Array for the results from add_new_blog
my @new_blog_result;

# Attempt to add a new blog.
@new_blog_result = $schema->resultset('Feed')->add_new_blog(%feed);

# Check the result
is($new_blog_result[0], 1, "Adding a new blog feed.");

# Attempt to add the same blog again.
@new_blog_result = $schema->resultset('Feed')->add_new_blog(%feed);

# Check the result
is($new_blog_result[0], 0, "Adding a duplicate blog feed.");

