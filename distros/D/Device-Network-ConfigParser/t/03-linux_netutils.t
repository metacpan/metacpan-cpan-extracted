#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

my @small_config_items = (
);

my @all_tests = (
    @small_config_items,
);

# + 1 is for the use_ok()
plan tests => 1 + @all_tests; 

use_ok( 'Device::Network::ConfigParser::Linux::NetUtils', qw{get_parser parse_config post_process} ) || print "Bail out!\n";

my $parser = get_parser();

# Run all tests
for my $test (@all_tests) {
    my $parsed = parse_config($parser, $test->{test});
    my $post_processed = post_process($parsed);

    is_deeply( $post_processed, $test->{p_proc}, $test->{desc} );
}
    


