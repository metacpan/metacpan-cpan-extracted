use warnings;
use strict;
use Test::More;
use File::Spec;
use Test::Warnings ':all';
use Test::Exception;

use Jenkins::i18n qw(load_properties);

dies_ok { load_properties('foobar.properties') }
'dies with missing warning parameter';
like $@, qr/warning\sis\srequired/, 'get the expected error message';

like( warning { load_properties( 'foobar.properties', 1 ) },
    qr/foo/, 'got expected warning' );

note('load_properties without warning enabled');
load_properties( 'foobar.properties', 0 );

my $sample = File::Spec->catfile( 't', 'samples', 'table_pt_BR.properties' );
note("Using sample $sample");
my $result = load_properties( $sample, 1 );
is( ref $result, 'HASH', 'result is a hash reference' );
cmp_ok( scalar( keys( %{$result} ) ), '>', 0, 'result has some keys on it' );

ok( exists( $result->{'No\ updates'} ), 'can find expected complex key' );

done_testing;

# -*- mode: perl -*-
# vi: set ft=perl :
