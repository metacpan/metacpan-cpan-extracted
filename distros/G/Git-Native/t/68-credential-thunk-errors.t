use Test2::V0;
use Git::Libgit2 qw( init_lib oid_from_hex );
use Git::Native::Remote ();
use FFI::Platypus::Buffer qw( scalar_to_buffer );

# Die-containment for Git::Native::Remote's FFI callback thunks.
#
# The credential half of this contract lives next to the rest of the
# credential-thunk tests in t/52-credential-callback.t (karr ticket 4). What is
# tested here is the sibling of that same bug class in _make_update_tips_thunk:
# it carried a bare `die` with no eval around it at all, so a NULL new-tip oid
# from libgit2 unwound a Perl exception out of the closure through libgit2's C
# frames during git_remote_fetch. Its natural home would be
# t/49-remote-callbacks.t, but that file was owned by a concurrent agent when
# this fix landed.
#
# Every callback in Remote.pm is invoked by libgit2 from C. A Perl exception
# crossing those frames is undefined behaviour, so the rule for all of them is:
# never die, warn and return a negative rc instead. These thunks are pure
# functions returning an FFI::Platypus::Closure (a blessed CODE ref), so the
# rule is checkable straight from Perl, with no remote involved:
#
#   int cb(const char *refname, const git_oid *a, const git_oid *b, void *data)

init_lib();

my $REFNAME = 'refs/remotes/origin/main';
my $HEX_OLD = '1234567890abcdef1234567890abcdef12345678';
my $HEX_NEW = 'fedcba0987654321fedcba0987654321fedcba09';

# A real git_oid, built the same way the rest of the distribution builds one.
# Returns ( $address, \$scalar ) - the scalar must outlive the address.
sub oid_cell {
  my ($hex) = @_;
  my $raw = defined $hex ? oid_from_hex($hex) : "\0" x 20;
  my ($addr) = scalar_to_buffer($raw);
  return ( $addr, \$raw );
}

subtest 'a NULL new tip is contained instead of unwinding into libgit2' => sub {
  my @updated;
  my ( $closure, $keep ) = Git::Native::Remote::_make_update_tips_thunk(
    \@updated,
  );

  my ( $old, $old_cell ) = oid_cell($HEX_OLD);

  my @warnings;
  my $rc;
  my $survived = lives {
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };
    $rc = $closure->( $REFNAME, $old, 0, 0 );
  };

  ok $survived,
    "the closure returns instead of dying out through libgit2's C frames";
  ok $rc < 0,
    'a new tip we cannot record aborts the fetch rather than reporting success';
  is scalar(@warnings), 1, 'the failure is diagnosed exactly once';
  like $warnings[0], qr/update_tips/,
    'the warning names the callback that failed';
  like $warnings[0], qr/\Q$REFNAME\E/,
    'the warning names the ref it happened on';
  is \@updated, [],
    'nothing is recorded, so the Result cannot claim a ref was updated';
};

subtest 'the recorded update survives the eval wrapper' => sub {
  my @updated;
  my ( $closure, $keep ) = Git::Native::Remote::_make_update_tips_thunk(
    \@updated,
  );

  my ( $old,  $old_cell )  = oid_cell($HEX_OLD);
  my ( $new,  $new_cell )  = oid_cell($HEX_NEW);
  my ( $zero, $zero_cell ) = oid_cell(undef);

  is $closure->( $REFNAME, $old, $new, 0 ), 0,
    'a normal ref update returns 0 so the fetch continues';
  is $closure->( 'refs/remotes/origin/topic', $zero, $new, 0 ), 0,
    'a brand-new ref returns 0 too';

  # libgit2 uses the all-zero oid as a sentinel on BOTH sides of update_tips:
  # as the old tip it means "did not exist here before", as the new tip it
  # means "the ref was deleted" (what fetch --prune reports for a stale mirror
  # ref). Both are normalised to undef, so `to` reads as "where it points now"
  # and its absence as "it is gone" - never as a ref that moved to the zero
  # oid. The end-to-end proof over file:// is t/49-remote-callbacks.t 4b; this
  # pins the same meaning at the thunk, with no remote involved.
  is $closure->( 'refs/remotes/origin/gone', $old, $zero, 0 ), 0,
    'a deleted ref returns 0 as well - a deletion is a normal report, not an '
    . 'error the fetch should be aborted over';

  is \@updated, [
    { ref => $REFNAME, from => $HEX_OLD, to => $HEX_NEW, reason => '' },
    { ref => 'refs/remotes/origin/topic', from => undef, to => $HEX_NEW, reason => '' },
    { ref => 'refs/remotes/origin/gone', from => $HEX_OLD, to => undef, reason => '' },
  ], 'all three updates are recorded with the same four keys, and each all-zero '
   . 'oid becomes undef: from => undef is a ref that did not exist yet, '
   . 'to => undef is a ref that was deleted - both readable without a magic constant';

  is [ map { $_->{to} } @updated ], [ $HEX_NEW, $HEX_NEW, undef ],
    'the deleted ref is reported as having no target at all, NOT as pointing '
   . 'at the 40-zero oid - that distinction is the whole point of the sentinel';

  is [ map { $_->{reason} } @updated ], [ '', '', '' ],
    'reason is "" on every fetch update, so a caller can test reason without '
   . 'knowing whether the Result came from a fetch or a push';
};

done_testing;
