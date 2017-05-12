#!perl
use strict;
use warnings;
no warnings 'redefine';
use Test::More tests => 22;
use Test::Exception;
use Test::File;
use Path::Class;
use lib 'lib';
use_ok('File::Copy::Reliable');

my $dir = dir( 't', 'tmp' );
$dir->rmtree;
$dir->mkpath;
$dir = $dir->stringify;

# first time around let's try success

my $source      = file( 't',  'pod.t' )->stringify;
my $destination = file( $dir, file($source)->basename )->stringify;
my $size        = -s $source;

file_exists_ok( $source, "$source exists" );
file_not_exists_ok( $destination, "$destination does not exist" );

copy_reliable( $source, $destination );

file_exists_ok( $destination, "$destination does exist" );
file_size_ok( $destination, $size, "$destination size is $size" );

unlink($destination);
copy_reliable( $source, $dir );

file_exists_ok( $destination, "$destination does exist" );
file_size_ok( $destination, $size, "$destination size is $size" );

$source = $destination;
$destination = file( $dir, 'new.t' );

file_exists_ok( $source, "$source exists" );
file_not_exists_ok( $destination, "$destination does not exist" );

move_reliable( $source, $destination );

file_not_exists_ok( $source, "$source does not exist" );
file_exists_ok( $destination, "$destination does exist" );
file_size_ok( $destination, $size, "$destination size is $size" );

# now try failure

$source      = file( 't',  'not_here.txt' )->stringify;
$destination = file( $dir, file($source)->basename )->stringify;

throws_ok { copy_reliable( $source, $destination ) }
qr{copy_reliable\(t/not_here.txt, t/tmp/not_here.txt\) failed: No such file or directory},
    'rethrows copy error';

throws_ok { move_reliable( $source, $destination ) }
qr{move_reliable\(t/not_here.txt, t/tmp/not_here.txt\) failed: No such file or directory},
    'rethrows move error';

$source      = file( 't',  'pod.t' );
$destination = file( $dir, $source->basename );

*File::Copy::Reliable::copy = sub { $! = 3141; return 0; };

throws_ok { copy_reliable( $source, $destination ) }
qr{copy_reliable\(t/pod.t, t/tmp/pod.t\) failed: Unknown error:? 3141},
    'rethrows copy error';

file_exists_ok( $source, "$source exists" );
file_not_exists_ok( $destination, "$destination does not exist" );

*File::Copy::Reliable::copy = sub { return 1 };

throws_ok { copy_reliable( $source, $destination ) }
qr{copy_reliable\(t/pod.t, t/tmp/pod.t\) failed copied 0 bytes out of 140},
    'rethrows copy error';

file_exists_ok( $source, "$source exists" );
file_not_exists_ok( $destination, "$destination does not exist" );

*File::Copy::Reliable::move = sub { $! = 3142; return 0; };

throws_ok { move_reliable( $source, $destination ) }
qr{move_reliable\(t/pod.t, t/tmp/pod.t\) failed: Unknown error:? 3142},
    'rethrows move error';

*File::Copy::Reliable::move = sub { return 1 };

throws_ok { move_reliable( $source, $destination ) }
qr{move_reliable\(t/pod.t, t/tmp/pod.t\) failed copied 0 bytes out of 140},
    'rethrows move error';

