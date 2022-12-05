use warnings;
use strict;
use Test::More tests => 15;
use Test::Exception;

use Jenkins::i18n::Stats;
my $package_name = 'Jenkins::i18n::Stats';

my $instance;
ok( $instance = Jenkins::i18n::Stats->new, 'can create a new instance' );
isa_ok( $instance, $package_name );

my @expected_attribs
    = sort(qw(keys missing unused empty same no_jenkins files unique_keys));
my @instance_attribs = sort( keys( %{$instance} ) );
is_deeply( \@instance_attribs, \@expected_attribs,
    'got all expected attributes from instance' );

my $expected_methods = dynamic_methods();

foreach my $name (qw(new summary add_key)) {
    push( @{$expected_methods}, $name );
}

can_ok( $package_name, @{$expected_methods} );

is( sum_counters(), 0, 'all counters have zero as value' );
ok( $instance->add_key('foobar'), 'can increment the "keys" counter' );
ok( $instance->add_key('foobar'), 'can increment the "keys" counter' );
ok( $instance->add_key('barfoo'), 'can increment the "keys" counter' );
is( $instance->get_keys, 3, '"keys" counter has the expected value' );
is( $instance->get_unique_keys,
    2, '"unique keys" counter has the expected value' );
dies_ok { $instance->_inc('foobar') } '_inc() dies with invalid counter name';
like( $@, qr/foobar/, 'got the expected error message' );
dies_ok { $instance->_inc } 'inc() dies with missing counter name';
like( $@, qr/required/, 'got the expected error message' );
is( $instance->perc_done, 100,
    'perc_done() returns all done since there are no problems' );

sub sum_counters {
    my $instance = shift;
    my $total    = 0;
    foreach my $attrib ( keys( %{$instance} ) ) {
        my $method = "get_$attrib";
        $total += $instance->$method();
    }
    return $total;
}

sub dynamic_methods {
    my @dynamic_based = qw(missing unused empty same no_jenkins files);
    my @methods;

    foreach my $attrib (@dynamic_based) {
        push( @methods, "inc_$attrib" );
        push( @methods, "get_$attrib" );
    }

    return \@methods;

}

# -*- mode: perl -*-
# vi: set ft=perl :
