use strict;
use warnings;
use FindBin qw($Bin);
use File::Spec::Functions;
use lib catfile( $Bin, 'lib' );
use Test::More tests => 4;
use Test::MyUtil;
use Iterator::ToArray;

my $for_deeply = [0, 1, 4, 9];

my $to_array = Iterator::ToArray->new( mk_iterator(3) );
my $array = $to_array->apply( sub { $_ * $_ } );

ok( $array && ref $array eq 'ARRAY', 'return arrayref in scalar context' );
is_deeply( $array, $for_deeply, 'struct ok' );

my @array = Iterator::ToArray->new( mk_iterator(3) )->apply( sub { $_ * $_ } );
is( scalar @array, 4, 'array length ok');
is_deeply( \@array, $for_deeply, 'struct ok' );
