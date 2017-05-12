#!perl

use strict;
use warnings;

use FindBin;
use File::Spec;
use File::Temp qw/tempdir/;
use File::Touch;

use Test::More;
use File::Find::Rule::Age;

my $test_dir = File::Temp->newdir( CLEANUP => 1 );
my $dir_name = $test_dir->dirname;

my $now   = DateTime->now();
my $today = DateTime->now();
$today->truncate( to => 'day' );
my $yesterday = DateTime->now();
$yesterday->truncate( to => 'day' );
$yesterday->subtract( days => 2 );

File::Touch->new( time => $now->epoch )->touch( File::Spec->catfile( $dir_name, 'newer' ) );
File::Touch->new( time => $yesterday->epoch )->touch( File::Spec->catfile( $dir_name, 'older' ) );

my @older = find(
    file => age => [ older => "1D" ],
    in   => $dir_name
);
is_deeply( \@older, [ File::Spec->catfile( $dir_name, 'older' ) ], "older" );
my @newer = find(
    file => age => [ newer => "1D" ],
    in   => $dir_name
);
is_deeply( \@newer, [ File::Spec->catfile( $dir_name, 'newer' ) ], "newer" );

SCOPE:
{
    my @warns;
    local $SIG{__WARN__} = sub { push @warns, @_ };
    my @fail = find(
        file => age => [ "ancient" => "1D" ],
        in   => $dir_name
    );
    cmp_ok( scalar @warns, "==", 1, "catched 1 warning for invalid criterion" );
    like( $warns[0], qr/^Invalid criterion: ancient/, "Criterion warning" );

    @warns = ();
    @fail  = find(
        file => age => [ "Newer" => "Mein, Dein Tag" ],
        in   => $dir_name
    );
    cmp_ok( scalar @warns, "==", 1, "catched 1 warning for missing operands" );
    like( $warns[0], qr/^Duration or Unit missing/, "Duration/Unit warning" );
}

done_testing;
