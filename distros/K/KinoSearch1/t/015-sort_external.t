use strict;
use warnings;

use lib 'buildlib';
use Test::More tests => 8;
use File::Spec;
use List::Util qw( shuffle );

BEGIN {
    use_ok("KinoSearch1::Util::SortExternal");
}
use KinoSearch1::Test::TestUtils qw( create_index );

my $invindex = create_index();

my ( $sortex, @orig, @sort_output );

sub init_sortex {
    $sortex = KinoSearch1::Util::SortExternal->new(
        invindex => $invindex,
        seg_name => '_1',
        @_,
    );
}

init_sortex;
@orig = ( 'a' .. 'z' );
$sortex->feed($_) for shuffle(@orig);
$sortex->sort_all;
while ( my $result = $sortex->fetch ) {
    push @sort_output, $result;
}
is_deeply( \@sort_output, \@orig, "sort letters" );
@orig        = ();
@sort_output = ();

init_sortex;
@orig = qw( a a a b c d x x x x x x y y );
$sortex->feed($_) for shuffle(@orig);
$sortex->sort_all;
while ( defined( my $result = $sortex->fetch ) ) {
    push @sort_output, $result;
}
is_deeply( \@sort_output, \@orig, "sort repeated letters" );
@orig        = ();
@sort_output = ();

init_sortex;
@orig = ( '', '', 'a' .. 'z' );
$sortex->feed($_) for shuffle(@orig);
$sortex->sort_all;
while ( defined( my $result = $sortex->fetch ) ) {
    push @sort_output, $result;
}
is_deeply( \@sort_output, \@orig, "sort letters and empty strings" );
@orig        = ();
@sort_output = ();

init_sortex( mem_threshold => 30 );
@orig = 'a' .. 'z';
$sortex->feed($_) for ( shuffle(@orig) );
$sortex->sort_all;
while ( my $result = $sortex->fetch ) {
    push @sort_output, $result;
}
is_deeply( \@sort_output, \@orig, "... with an absurdly low mem_threshold" );
@orig        = ();
@sort_output = ();

init_sortex( mem_threshold => 1 );
@orig = 'a' .. 'z';
$sortex->feed($_) for ( shuffle(@orig) );
$sortex->sort_all;
while ( my $result = $sortex->fetch ) {
    push @sort_output, $result;
}
is_deeply( \@sort_output, \@orig, "... with an even lower mem_threshold" );
@orig        = ();
@sort_output = ();

init_sortex;
$sortex->sort_all;
@sort_output = $sortex->fetch;
is_deeply( \@sort_output, [undef], "Sorting nothing returns undef" );
@sort_output = ();

init_sortex( mem_threshold => 20_000 );
@orig = map { pack( 'N', $_ ) } ( 0 .. 11_000 );
$sortex->feed( shuffle(@orig) );
$sortex->sort_all;
while ( defined( my $item = $sortex->fetch ) ) {
    push @sort_output, $item;
}
is_deeply( \@sort_output, \@orig, "Sorting packed integers..." );
@sort_output = ();
exit;

init_sortex( mem_threshold => 20_000 );
@orig = ();
for my $iter ( 0 .. 1_000 ) {
    my $string = '';
    for my $string_len ( 0 .. int( rand(1200) ) ) {
        $string .= pack( 'C', int( rand(256) ) );
    }
    push @orig, $string;
}
@orig = sort @orig;
$sortex->feed($_) for shuffle(@orig);
$sortex->sort_all;
while ( defined( my $item = $sortex->fetch ) ) {
    push @sort_output, $item;
}
is_deeply( \@sort_output, \@orig, "Random binary strings of random length" );
@sort_output = ();
