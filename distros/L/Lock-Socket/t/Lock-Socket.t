use strict;
use warnings;
use Lock::Socket;
use Test::More;
use Test::Fatal;

# First of all test the Error class
my $error = Lock::Socket::Error->new( msg => 'usage error' );
isa_ok $error , 'Lock::Socket::Error';
is "$error", 'usage error', 'error stringification';

like exception { Lock::Socket->new }, qr/required/, 'required attributes';

my $PORT1 = 14414 + int( rand(1000) );
my $PORT2 = 24414 + int( rand(1000) );

# Now take a lock
my $sock = Lock::Socket->new( port => $PORT1 );
isa_ok $sock, 'Lock::Socket';

like $sock->addr,    qr/^127.\d+.\d+.1$/, $sock->addr . ' is saved';
is $sock->is_locked, 0,                   'new not locked';
is $sock->lock,      1,                   'lock';
is $sock->is_locked, 1,                   'is_locked';
is $sock->lock,      1,                   'lock ok when locked';
is $sock->unlock,    1,                   'unlock ok';
is $sock->unlock,    1,                   'unlock still ok';
is $sock->lock,      1,                   're-lock ok';

# Cannot take the same lock
my $e = exception {
    Lock::Socket->new( port => $PORT1 )->lock;
};
isa_ok $e, 'Lock::Socket::Error::Bind';

# Can try to take the lock
is( Lock::Socket->new( port => $PORT1 )->try_lock, 0, 'try fail' );

# But can take a different lock port
my $sock2 = Lock::Socket->new( port => $PORT2 );
is $sock2->lock, 1, 'lock 2';

# And can get it by trying
$sock2 = undef;
$sock2 = Lock::Socket->new( port => $PORT2 );
is $sock2->try_lock, 1, 'try_lock 2';

# We can also take the same port at a different address
my $sock3 = Lock::Socket->new( port => $PORT2, addr => '127.0.0.2' );

# 127.0.0.2 doesn't exist on BSDs
if ( $sock3->try_lock == 1 ) {

    # But we can't take that lock again either
    $e = exception {
        Lock::Socket->new(
            port => $PORT2,
            addr => '127.0.0.2'
        )->lock;
    };
    isa_ok $e, 'Lock::Socket::Error::Bind';
}

# Confirm that a lock disappears with the object
undef $sock;
my $sock4 = Lock::Socket->new( port => $PORT1 );
is $sock4->lock, 1, 'lock 4';

done_testing();
