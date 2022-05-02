use warnings;
use strict;
use Test::More tests => 13;
use Test::Exception;
use Test::Warnings qw(:all);

use Jenkins::i18n::Stats;
my $package_name = 'Jenkins::i18n::Stats';

my @methods = qw(new inc summary);
can_ok( $package_name, @methods );
my $instance;
ok( $instance = Jenkins::i18n::Stats->new, 'can create a new instance' );
isa_ok( $instance, $package_name );
my @expected_attribs
    = sort(qw(keys missing unused empty same no_jenkins files));
my @instance_attribs = sort( keys( %{$instance} ) );
is_deeply( \@instance_attribs, \@expected_attribs,
    'got all expected attributes from instance' );
my $total = 0;

foreach my $counter ( values( %{$instance} ) ) {
    $total += $counter;
}

is( $total, 0, 'all counters have zero as value' );
like( warning { $instance->summary },
    qr/Not\sa\ssingle\skey/, 'got expected warning from summary()' );
ok( $instance->inc('keys'), 'can increment the "keys" counter' );
is( $instance->{keys}, 1, '"keys" counter value is the expected' );
dies_ok { $instance->inc('foobar') } 'inc() dies with invalid counter name';
like( $@, qr/foobar/, 'got the expected error message' );
dies_ok { $instance->inc } 'inc() dies with missing counter name';
like( $@, qr/required/, 'got the expected error message' );

# -*- mode: perl -*-
# vi: set ft=perl :
