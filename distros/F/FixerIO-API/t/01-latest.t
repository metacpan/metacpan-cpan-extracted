#!perl
use strict;
use warnings;
use Test::More;

my $module = 'FixerIO::API';
require_ok( $module );

can_ok( $module, qw( new api_call latest ));

my $access_key = undef;
my $fixer = $module->new( $access_key );

is($fixer, undef);

$access_key = 'nonsense_string';
$fixer = $module->new( $access_key );

isa_ok( $fixer, $module );

my $r = $fixer->latest;
is $r->{error}{code}, 101, 'Invalid access key? Yes, '.$r->{error}{info};

done_testing();
