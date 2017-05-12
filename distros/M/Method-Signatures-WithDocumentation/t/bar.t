#!perl -w

use Test::Most;
use Sub::Documentation qw(get_documentation);
use YAML::Any qw(LoadFile);
use lib 't/lib';

plan tests => 2;

use_ok("t::lib::bar");

my @A = LoadFile('t/bar.yml');
my @B = get_documentation();

is_deeply(\@A => \@B);

done_testing();
