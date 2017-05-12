use strict;
use warnings;
use Test::More tests => 19;
use File::Temp qw(tempdir);

BEGIN {
    use_ok( 'Filesys::DiskUsage', 'du' );
}

is( du(), 0 );

is( du( { recursive => 0 }, "t/samples" ), 0 );

is( du( { recursive => 0 }, <t/samples/[1-8]> ), 30 );

is_deeply( [ du( sort <t/samples/[1-8]> ) ] , [4,4,4,5,5,4,2,2] );

is_deeply( {du( { 'make-hash' => 1 }, 't/samples/1' )},{ 't/samples/1' => 4 } );

is( du( { recursive => 0 } , <t/samples/*> ), 30 );

is( du( { 'show-warnings' => 0, recursive => 1, 'max-depth' => 1 } , <t/samples/*> ), 38 );

is( du( { 'show-warnings' => 0, recursive => 1, 'max-depth' => 1 } , 't/samples' ), 30 );

is( du( { 'show-warnings' => 0, recursive => 1 } , 't/samples' ), 38 );

is( du( { 'show-warnings' => 0, recursive => 1 , exclude => qr/1/ } , 't/samples' ), 34 );

is( du( { 'show-warnings' => 0, recursive => 1 , exclude => qr/[12]/ } , 't/samples' ), 30 );

is( du( { 'show-warnings' => 0, recursive => 1 , exclude => qr/\d/ } , 't/samples' ), 0 );

is( du( { recursive => 0 , 'human-readable' => 1 , 'truncate-readable' => 0 } , 't/samples' ), '0B' );

is( du( { recursive => 0 , 'human-readable' => 1 , 'truncate-readable' => -1 } , 't/samples' ),'0B' );

is( du( { recursive => 0 , 'human-readable' => 1 } , 't/samples' ), '0.00B' );

is( du( { recursive => 0 , 'Human-readable' => 1 } , 't/samples' ), '0.00B' );

SKIP: {
    skip "No symlinks on Windows", 2 if $^O =~ /win32/i;

    my $dir = tempdir( CLEANUP => 1 );
    #diag $dir;

    mkdir "$dir/a" or die;
    mkdir "$dir/a/b" or die;
    symlink "$dir/a", "$dir/a/b/c" or die;
    write_file("$dir/a/b/data", "some text");
    write_file("$dir/a/in_root", "more text");

    is( du( "$dir/a/b" ), '9', 'not following symlinks' );
    is( du( { dereference => 1 },  "$dir/a/b" ), '18', 'following symlink' );
}

sub write_file {
    my ($file, $data) = @_;
    open my $fh, '>', $file or die;
    print $fh $data;
    close $fh;
}

