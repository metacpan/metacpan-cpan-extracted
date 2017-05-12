#########################
# GnomePrint2 Tests
#       - ebb
#########################

#########################

use Test::More tests => 3;
BEGIN { use_ok('Gnome2::Print') };

#########################

$config = Gnome2::Print::Config->default;

ok($job = Gnome2::Print::Job->new($config));

$job->close;
ok(1);
