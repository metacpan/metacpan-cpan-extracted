use t::boilerplate;

use Test::More;
use English qw( -no_match_vars );
use File::DataClass::Exception;
use File::DataClass::IO;
use File::Spec::Functions qw( catfile );

use_ok 'IPC::SRLock';

my $is_win32 = ($OSNAME eq 'MSWin32') || ($OSNAME eq 'cygwin');

my $lock = IPC::SRLock->new( { tempdir => 't', type => 'fake' } );

is ref $lock->list, 'ARRAY', 'Fake list is empty';
is $lock->set( k => 1 ), 1, 'Sets fake lock';
is $lock->reset, 1, 'Resets fake lock';

$lock = IPC::SRLock->new( { tempdir => 't', type => 'fcntl' } ); my $e;

isa_ok $lock, 'IPC::SRLock';

eval { $lock->set() };

if ($e = File::DataClass::Exception->caught()) {
   like "${e}", qr{ \Qnot specified\E }mx, 'Error no key';
}
else {
   ok 0, 'Expected set error missing';
}

eval { $lock->reset( k => $PROGRAM_NAME ) };

if ($e = File::DataClass::Exception->caught()) {
   is $e->error, 'Lock [_1] not set', 'Error not set';
   ok $e->args->[ 0 ] eq $PROGRAM_NAME, 'Error args';
}
else {
   ok 0, 'Expected reset error missing';
}

$lock->set( { k => $PROGRAM_NAME } );

is [ map { $_->{key} } @{ $lock->list() } ]->[ 0 ], $PROGRAM_NAME,
   'Set - fcntl';

$lock->reset( k => $PROGRAM_NAME );

is [ map { $_->{key} } @{ $lock->list() } ]->[ 0 ], undef, 'Reset - fcntl';

my $lockf = io[ 't', 'ipc_srlock.lck' ]; my $shmf = io[ 't', 'ipc_srlock.shm' ];

ok $lockf->exists && $lockf->is_file, 'Lock file exists - fcntl';
ok $shmf->exists && $shmf->is_file, 'Shm file exists - fcntl';

is $lock->_implementation->_sleep_or_timeout, 1, 'Sleep or timeout sleeps';

$lockf->exists and $lockf->unlink; $shmf->exists and $shmf->unlink;

$lockf = io[ 't', 'tlock' ]; $shmf = io[ 't', 'tshm' ];

$lockf->exists and $lockf->unlink; $shmf->exists and $shmf->unlink;

$lock = IPC::SRLock->new( { debug    => 1,
                            lockfile => catfile( qw( t tlock ) ),
                            patience => 100,
                            shmfile  => catfile( qw( t tshm ) ),
                            tempdir  => 't',
                            type     => '+IPC::SRLock::Fcntl' } );

$lock->set( k => $PROGRAM_NAME, p => 100, t => 100 );

is $lock->list->[ 0 ]->{pid}, 100, 'Non default pid - fcntl';

is $lock->list->[ 0 ]->{timeout}, 100, 'Non default timeout - fcntl';

is $lock->get_table->{count}, 1, 'Get table has count - fcntl';

like $lock->_implementation->_timeout_error( 0, 0, 0, 0 ),
   qr{ 0 \s set \s by \s 0 }mx, 'Timeout error - fcntl';

is $lock->set( k => $PROGRAM_NAME, async => 1 ), 0, 'Async lock - fcntl';

eval { $lock->reset( k => $PROGRAM_NAME ) };

like $EVAL_ERROR, qr{ \Qanother process\E }mx, 'Reset only our locks - fcntl';

$lock->reset( k => $PROGRAM_NAME, p => 100 );

is $lock->get_table->{count}, 0, 'Get table has no count - fcntl';

$lockf->exists and $lockf->unlink; $shmf->exists and $shmf->unlink;

eval { $lock->_implementation->_sleep_or_timeout( 0, time, 'test' ) };

like $EVAL_ERROR, qr{ \Qtimed out\E }mx, 'Sleep or timeout timed out';

is $lock->_implementation->_sleep_or_timeout( 1, 1, 'test' ), 1,
   'Sleep or timeout returns true';

SKIP: {
   $is_win32 and skip 'tests: OS unsupported', 5;

   my $key = 12244237 + int( rand( 4096 ) );

   eval { $lock = IPC::SRLock->new( { lockfile => $key, type => 'sysv' } ) };

   my $e = $EVAL_ERROR; $e and $e =~ m{ No \s+ space }mx
      and skip 'tests: No shared memory space', 5;

   $lock->set( k => $PROGRAM_NAME );

   is [ map { $_->{key} } @{ $lock->list() } ]->[ 0 ], $PROGRAM_NAME,
      'Set - sysv';

   $lock->reset( k => $PROGRAM_NAME );

   is [ map { $_->{key} } @{ $lock->list() } ]->[ 0 ], undef, 'Reset - sysv';

   $lock = IPC::SRLock->new( { debug => 1, lockfile => $key, type => 'sysv' } );

   is $lock->set( k => $PROGRAM_NAME, p => 100, t => 100 ), 1,
      'Set returns true - sysv';

   is $lock->list->[ 0 ]->{pid}, 100, 'Non default pid - sysv';

   is $lock->list->[ 0 ]->{timeout}, 100, 'Non default timeout - sysv';

   is $lock->get_table->{count}, 1, 'Get table has count - sysv';

   is $lock->set( k => $PROGRAM_NAME, async => 1 ), 0, 'Async lock - sysv';

   eval { $lock->reset( k => $PROGRAM_NAME ) };

   like $EVAL_ERROR, qr{ \Qanother process\E }mx, 'Reset only our locks - sysv';

   $lock->reset( k => $PROGRAM_NAME, p => 100 );

   is $lock->get_table->{count}, 0, 'Get table has no count - sysv';

   qx{ ipcrm -M $key }; qx{ ipcrm -S $key };
}

SKIP: {
   ($ENV{AUTHOR_TESTING} and $ENV{HAVE_MEMCACHED})
      or skip 'author tests: Needs a memcached server', 2;
   $lock = IPC::SRLock->new( { patience => 10, type => 'memcached' } );
   $lock->set( k => $PROGRAM_NAME );

   is [ map { $_->{key} } @{ $lock->list() } ]->[ 0 ], $PROGRAM_NAME,
      'Set - memcached';

   $lock->reset( k => $PROGRAM_NAME );

   is [ map { $_->{key} } @{ $lock->list() } ]->[ 0 ], undef,
      'Reset - memcached';
}

eval { IPC::SRLock::Constants->Exception_Class( 'wrong' ) };

like $EVAL_ERROR, qr{ \Qnot loaded\E }mx, 'Bad exception class';

is IPC::SRLock::Constants->Exception_Class( 'Unexpected' ), 'Unexpected',
   'Sets exception class';

use IPC::SRLock::Utils qw( merge_attributes );

my $dest = { xd => q(), xu => undef };
my $src  = {  x => 'y', xd => 'z', xu => undef };

merge_attributes $dest, $src;
merge_attributes $dest, $src, [ 'x', 'xd', 'xu' ];
merge_attributes $dest, $lock, [ 'type', 'foo' ];

is $dest->{x}, 'y', 'Merge attributes - normal';
is $dest->{xd}, '', 'Merge attributes - defined';
is $dest->{xu}, undef, 'Merge attributes - undefined';

done_testing;

# Local Variables:
# mode: perl
# tab-width: 3
# End:
