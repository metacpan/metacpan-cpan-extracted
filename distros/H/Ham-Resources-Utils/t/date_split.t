#!perl -T

use strict;
use warnings;
use Test::More tests=>5;

my $m = Ham::Resources::Utils->new();
BEGIN { use_ok('Ham::Resources::Utils') };

# Check DATE_SPLIT() function
my $date = "28-6-2012";

ok( defined $m			, 'new() creation');


my @date_ = $m->date_split($date);

ok( $date_[0] == 28,		'day split completed');
ok( $date_[1] == 6,		'mounth split cpompleted');
ok( $date_[2] == 2012,		'year split completed');


done_testing();

