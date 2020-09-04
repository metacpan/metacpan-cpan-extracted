#! perl

use Test2::V0;
use IO::Handle;
use IO::ReStoreFH;
use Test::Lib;

use My::Test;

test_wfh 'new: fh >', '>', sub { IO::ReStoreFH->new( $_[0] ) };

test_wfh 'new: fh >>', '>>', sub { IO::ReStoreFH->new( $_[0] ) };

test_wfh 'new: fh +>', '+>', sub { IO::ReStoreFH->new( $_[0] ) };

like( dies { IO::ReStoreFH->new( 3.2 ) }, qr/must be opened/, 'bad fd' );

like(
    dies { IO::ReStoreFH->new( bless {} ) },
    qr/not an open filehandle/,
    'no fileno method'
);

like(
    dies { IO::ReStoreFH->new( IO::Handle->new ) },
    qr/not an open filehandle/,
    'undefined fileno'
);

# try and make fcntl fail to test rest of mode setting code
{
    package MyTest;
    sub new    { bless {}, shift; }
    sub fileno { return 22; }
}

like(
    dies { IO::ReStoreFH->new( MyTest->new ) },
    qr/not an open filehandle/i,
    'defined fileno'
);

done_testing;
