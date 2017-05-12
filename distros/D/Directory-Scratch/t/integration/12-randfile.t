#!/usr/bin/perl
# 12-randfile.t 
# Copyright (c) 2006 Rockway <jrockway@cpan.org>
# Copyright (c) 2006 Al Tobey <tobeya@cpan.org>

use Test::More;
use Directory::Scratch;
eval "use String::Random";
plan skip_all => "Requires String::Random" if $@;
plan tests => 109;

# I run local tests of 512 or more to exhaust the chances entropy is causing
# tests to pass that might fail on client machines
# 20 should suffice for clients downloading from CPAN
my $loop_iterations = 20;

my $temp = Directory::Scratch->new;

ok( my $rfile = $temp->randfile, "randfile()" );
ok( length($rfile), "randfile() returned a string" );
ok( -e $rfile, "file exists" );
ok( unlink($rfile), "file unlink() succeeds" );

$rfile = undef;

sub test_iterations {
    for my $i (1..$loop_iterations) {
        ok( $rfile = $temp->randfile( 1024, 2048 ), "$i: randfile( 1024, 2048 )" );
        my $size = -s $rfile;
        ok( -e $rfile, "  $i: File exists." );
        cmp_ok( $size, '>=', 1024, "  $i: size of file: $size > 1024" );
        cmp_ok( $size, '<=', 2048, "  $i: size of file: $size < 2048" );
    }
}

test_iterations();

my $j = 1;
for ( my $i=1; $i<=1000000; $i *= 10 ) {
    ok( my $file = $temp->randfile($j, $i), "randfile($j, $i)" );
    my $size = -s $file;
    if ( $size <= $i && $size >= $j ) {
        pass( "  check file size" );
    }
    else {
        fail( "  check file size ( $size <= $i && $size >= $j )" );
    }
    $j = $i;
    unlink $file;
}

for ( my $i=1; $i<=1024;  $i *= 2 ) {
    ok( my $file = $temp->randfile($i), "randfile($i)" );
}

