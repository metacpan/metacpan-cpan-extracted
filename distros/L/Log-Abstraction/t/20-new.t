#!perl -w

use strict;

# use lib 'lib';
use Test::Most tests => 7;

BEGIN { use_ok('Log::Abstraction') }

isa_ok(Log::Abstraction->new(), 'Log::Abstraction', 'Creating Log::Abstraction object');
isa_ok(Log::Abstraction::new(), 'Log::Abstraction', 'Creating Log::Abstraction object');
isa_ok(Log::Abstraction->new()->new(), 'Log::Abstraction', 'Cloning Log::Abstraction object');
# ok(!defined(Log::Abstraction::new()));

# Create a new object with direct key-value pairs
my @array;
my $logger = Log::Abstraction->new(script_name => 'foo', logger => \@array);
cmp_ok($logger->{script_name}, 'eq', 'foo', 'direct key-value pairs');

# Test cloning behaviour by calling new() on an existing object
my $logger2 = $logger->new(script_name => 'bar');
cmp_ok($logger2->{logger}, 'eq', \@array, 'clone keeps old args');
cmp_ok($logger2->{script_name}, 'eq', 'bar', 'clone adds new args');
