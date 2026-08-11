use Test2::V0;
use lib 't/lib';
use TestRepo;
use Git::Native;
use Git::Native::Remote ();
use Git::Libgit2::FFI ();

# Network-free unit test for Remote::_build_strarray - the function that hands
# a Perl arrayref of refspecs to libgit2 as a git_strarray. Every fetch and
# push goes through it, but only ever with a populated arrayref, so neither
# the "no refspecs" contract (a NULL strarray, which libgit2 reads as "use the
# refspecs configured in .git/config") nor the arrayref type guard had a test.
#
# The struct is hand-packed Perl memory - {char **strings; size_t count} - so
# the layout is asserted by reading it back the same way libgit2 would.

my ( $repo, $tmp ) = TestRepo::new_repo();

subtest 'no refspecs means a NULL strarray' => sub {
  # NULL is meaningful here: libgit2 falls back to the remote's configured
  # refspecs. Returning a zero-length strarray instead would mean "transfer
  # nothing", which is a different operation.
  my ( $ptr, $keep ) = Git::Native::Remote::_build_strarray(undef);
  is $ptr, 0, 'undef refspecs -> NULL strarray pointer';
  is $keep, [], 'and nothing to keep alive';

  my ( $ptr2, $keep2 ) = Git::Native::Remote::_build_strarray( [] );
  is $ptr2, 0, 'an empty arrayref -> NULL strarray pointer too';
};

subtest 'refspecs must be an arrayref' => sub {
  my $err = dies { Git::Native::Remote::_build_strarray('refs/heads/main') };
  like $err, qr/_build_strarray: refspecs must be an arrayref/,
    'a plain string is rejected';
  ok !ref($err), 'and it is a croak, not a libgit2 error';

  my $hash_err = dies { Git::Native::Remote::_build_strarray( {} ) };
  like $hash_err, qr/must be an arrayref/, 'a hashref is rejected too';

  # The guard sits in front of the FFI, so it protects the public entry
  # points before anything touches the network.
  my $remote = $repo->remote_anonymous('file:///nonexistent');
  my $fetch_err = dies { $remote->fetch( refspecs => 'refs/heads/main' ) };
  like $fetch_err, qr/must be an arrayref/,
    'fetch rejects a non-arrayref refspecs before connecting';
};

subtest 'the packed git_strarray describes exactly the refspecs given' => sub {
  my @specs = ( '+refs/karr/*:refs/karr/*', 'refs/heads/main:refs/heads/main' );
  my ( $ptr, $keep ) = Git::Native::Remote::_build_strarray( \@specs );
  ok $ptr, 'a non-empty list gets a real strarray pointer';
  ok scalar(@$keep), 'and a keepalive holding the Perl-owned buffers';

  # {char **strings; size_t count} - 8 bytes each on the LP64 platforms this
  # distribution targets, which is the same assumption tag_names makes.
  my ( $strings_ptr, $count ) =
    unpack 'JJ', Git::Native::Remote::_peek_bytes( $ptr, 16 );
  is $count, scalar(@specs), 'count matches the number of refspecs';
  ok $strings_ptr, 'the strings pointer is not NULL';

  my $ffi = Git::Libgit2::FFI::ffi();
  my @read_back;
  for my $i ( 0 .. $count - 1 ) {
    my $sp = $ffi->cast( 'opaque', 'opaque[' . ( $i + 1 ) . ']', $strings_ptr )->[$i];
    push @read_back, $ffi->cast( 'opaque', 'string', $sp );
  }
  is \@read_back, \@specs,
    'reading the array back the way libgit2 does yields the same strings in order';
};

subtest 'the strings are copies, not aliases of the caller list' => sub {
  # _build_strarray copies each refspec so the C side has storage we control;
  # mutating the caller's array afterwards must not change what libgit2 sees.
  my @specs = ('refs/heads/main:refs/heads/main');
  my ( $ptr, $keep ) = Git::Native::Remote::_build_strarray( \@specs );
  $specs[0] = 'refs/heads/CLOBBERED:refs/heads/CLOBBERED';

  my ( $strings_ptr, $count ) =
    unpack 'JJ', Git::Native::Remote::_peek_bytes( $ptr, 16 );
  my $ffi = Git::Libgit2::FFI::ffi();
  my $sp  = $ffi->cast( 'opaque', 'opaque[1]', $strings_ptr )->[0];
  is $ffi->cast( 'opaque', 'string', $sp ),
    'refs/heads/main:refs/heads/main',
    'the packed string is unaffected by a later change to the caller array';
};

done_testing;
