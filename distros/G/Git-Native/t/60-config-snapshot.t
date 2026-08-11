use Test2::V0;
use lib 't/lib';
use TestRepo;
use Git::Native;

# t/39-config.t reads and writes through Repository->config / config_snapshot.
# Git::Native::Config->snapshot itself - the method that makes a read-only
# copy out of an existing handle - was never called, and neither was the
# writable/read-only distinction it creates. That distinction is the whole
# reason config_string goes through a snapshot, so it deserves a test.

my ( $repo, $tmp ) = TestRepo::new_repo();

my $live = $repo->config;
$live->set_string( 'user.name', 'First Name' );

subtest 'Config->snapshot makes a readable copy' => sub {
  my $snap = $live->snapshot;
  isa_ok $snap, ['Git::Native::Config'], 'snapshot returns a Config';
  is $snap->get_string('user.name'), 'First Name', 'the snapshot reads the value';
  is $snap->get_string('not.set'), undef, 'an unset key is undef on a snapshot';
};

subtest 'a snapshot is a point-in-time copy, not a live view' => sub {
  # This is why config_string takes a fresh snapshot on every call: an old
  # snapshot keeps answering with the value it was taken at.
  my $snap = $live->snapshot;
  $live->set_string( 'user.name', 'Second Name' );

  is $snap->get_string('user.name'), 'First Name',
    'the old snapshot still reports the value it was taken at';
  is $repo->config_string('user.name'), 'Second Name',
    'config_string takes a fresh snapshot and sees the new value';
  is $live->snapshot->get_string('user.name'), 'Second Name',
    'a newly taken snapshot sees the new value too';
};

subtest 'a snapshot refuses writes' => sub {
  # All backends in a snapshot are read-only; the failure has to come back
  # as a Git::Native::Error rather than silently doing nothing.
  #
  # The key is read before and after rather than asserted to be undef:
  # libgit2 1.5 ignores GIT_CONFIG_GLOBAL, so a developer's real
  # ~/.gitconfig can supply user.email here (see the TestRepo isolation
  # ticket). What must hold either way is that the refused write changed
  # nothing.
  my $before = $repo->config_string('user.email');

  my $snap = $live->snapshot;
  my $err  = dies { $snap->set_string( 'user.email', 'nope@example.invalid' ) };
  isa_ok $err, ['Git::Native::Error'], 'set_string on a snapshot throws';
  ok !$err->isa('Git::Libgit2::Error'), 'the low-level error does not leak';
  ok $err->code < 0, 'with a negative libgit2 code';
  like $err->message, qr/readonly/i, 'the message says the backends are read-only';

  is $repo->config_string('user.email'), $before,
    'and nothing was written';
  isnt $repo->config_string('user.email'), 'nope@example.invalid',
    'in particular the refused value did not land';
};

subtest 'set_string returns the config for chaining' => sub {
  ref_is $live->set_string( 'a.b', 'c' ), $live, 'set_string returns $self';
  is $repo->config_string('a.b'), 'c', 'the chained write took effect';
};

subtest 'a snapshot of a snapshot still reads' => sub {
  # snapshot() passes _owner along, so the repository stays alive behind a
  # nested snapshot; if that ownership were dropped this read would be a
  # use-after-free rather than a value.
  my $nested = $live->snapshot->snapshot;
  is $nested->get_string('a.b'), 'c', 'the nested snapshot reads the value';
};

done_testing;
