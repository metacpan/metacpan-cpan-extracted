#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

my @small_config_items = (
    #{
    #    test        => q{name 192.0.2.1 Named_Host},
    #    p_proc      => [ { type => 'name', config => { alias => 'Named_Host', ip => '192.0.2.1' } } ],
    #    desc        => q{Name Alias}
    #},
);

my @all_tests = (
    @small_config_items,
);

# + 1 is for the use_ok()
plan tests => 1 + @all_tests; 

use_ok( 'Device::Network::ConfigParser::CheckPoint::Expert', qw{get_parser parse_config post_process} ) || print "Bail out!\n";

my $parser = get_parser();

# Run all tests
for my $test (@all_tests) {
    my $parsed = parse_config($parser, $test->{test});
    my $post_processed = post_process($parsed);

    is_deeply( $post_processed, $test->{p_proc}, $test->{desc} );
}
    


