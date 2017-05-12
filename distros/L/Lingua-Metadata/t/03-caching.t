use strict;
use warnings;

use Time::HiRes;
use Test::More tests => 2;
BEGIN { use_ok('Lingua::Metadata') };

my $initial_start = Time::HiRes::time();
my $cs_metadata = Lingua::Metadata::get_language_metadata("cs");
my $initial_time = Time::HiRes::time() - $initial_start;

my $following_start = Time::HiRes::time();
my $ces_metadata = Lingua::Metadata::get_language_metadata("ces");
my $following_time = Time::HiRes::time() - $following_start;

ok($following_time < $initial_time, "Following time " . $following_time . " has to be lower than initial time " . $initial_time);
