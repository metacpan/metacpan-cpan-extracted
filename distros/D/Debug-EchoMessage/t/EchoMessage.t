# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

use strict;
use warnings;

use Test::More qw(no_plan);

my $class = 'main';
my $obj = bless {}, $class; 
use Debug::EchoMessage qw(:all); 

isa_ok($obj, $class);

my @md = @Debug::EchoMessage::EXPORT_OK; 
foreach my $m (@md) {
    ok($obj->can($m), "$class->can('$m')");
}


