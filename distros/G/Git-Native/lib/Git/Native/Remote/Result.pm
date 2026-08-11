# ABSTRACT: Per-ref outcomes from a Remote fetch or push

package Git::Native::Remote::Result;
use Moo;
use Carp ();
use namespace::clean;

# Result of a Git::Native::Remote fetch or push. libgit2 returns 0 even when
# individual refs were rejected or skipped; the only way to learn about it
# is via the per-ref callbacks (update_tips for fetch, push_update_reference
# for push). This class is the structured surface for those outcomes.
#
#   $remote->fetch(...);   # returns $result
#   for my $u (@{$result->updated})  { say "$u->{ref}: $u->{from} -> $u->{to}" }
#   for my $r (@{$result->rejected}) { say "$r->{ref}: $r->{reason}" }
#
# updated entries always carry the SAME four keys, whichever operation
# produced them — { ref, from, to, reason } — so a caller can read any of
# them without knowing where the Result came from, and a missing value is an
# explicit undef rather than an absent key:
#
#   fetch: { ref => $local_name,  from => $oid_hex|undef, to => $oid_hex|undef, reason => '' }
#   push:  { ref => $remote_name, from => undef,          to => $oid_hex|undef, reason => '' }
#
#   from is undef on push: push_update_reference reports a per-ref verdict,
#     not the oid range, and the previous remote-side oid would cost an extra
#     git_remote_ls round trip. to is recovered from the local source ref.
#   to is undef when the ref was deleted (fetch prune, push delete refspec).
#   reason is '' on both — a non-empty reason means rejected, see below.
# rejected entries: { ref => $name, reason => $status_str }
#   - On push: reason is the libgit2 status string the server sent (e.g.
#     "non-fast-forward", "pre-receive hook declined"). reason is "" (empty
#     string, not undef) when the server reported success for that ref with
#     no specific message.
#   - On fetch: reason is currently always "" — the update_tips callback only
#     fires on accepted updates; libgit2's "non-fast-forward skipped" path
#     does NOT route through it. Kept for API symmetry.
#
# ok() returns true iff both lists are empty — i.e. every ref succeeded
# without an explicit "skipped" or "rejected" signal. Note that on a
# successful push of N refs, all N land in `updated` and `ok` is false;
# `ok` is mostly useful for "I expected N updates, did anything fail?".
has updated  => ( is => 'ro', default => sub { [] } );
has rejected => ( is => 'ro', default => sub { [] } );

sub ok { !@{ $_[0]->updated } && !@{ $_[0]->rejected } }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Git::Native::Remote::Result - Per-ref outcomes from a Remote fetch or push

=head1 VERSION

version 0.005

=head1 SYNOPSIS

  my $r = $remote->fetch(
    refspecs => ['+refs/heads/*:refs/remotes/origin/*'],
  );
  if ( !$r->ok ) {
    for my $u ( @{ $r->updated } ) {
      warn sprintf "updated %s: %s -> %s\n", $u->{ref},
        $u->{from} // '(new)', $u->{to} // '(deleted)';
    }
    for my $u ( @{ $r->rejected } ) {
      warn "rejected $u->{ref}: $u->{reason}\n";
    }
  }

=head1 DESCRIPTION

Structured return value from L<Git::Native::Remote>'s C<fetch> and C<push>.
It exists because libgit2 returns 0 from C<git_remote_fetch> /
C<git_remote_push> even when individual refs were skipped or refused; the
per-ref outcome is only visible through the callbacks C<Remote> installs
(C<update_tips> on fetch, C<push_update_reference> on push). See
L</updated>, L</rejected>, and L</ok>.

=head2 updated

  for my $u ( @{ $result->updated } ) {
    say $u->{ref}, defined $u->{to} ? " -> $u->{to}" : ' (deleted)';
  }

Arrayref of hashrefs, one per ref that actually moved on the receiving
side. Every entry carries the same four keys, C<ref> / C<from> / C<to> /
C<reason>, whether it came from a fetch or a push, so code that reads a
Result does not have to know which operation produced it. A value the
operation cannot supply is present as an explicit C<undef> rather than as
a missing key.

  # fetch
  { ref => 'refs/karr/x', from => undef, to => 'b8f9ae41...', reason => '' }
  # push
  { ref => 'refs/karr/x', from => undef, to => 'b8f9ae41...', reason => '' }

C<ref> is the name of the ref on the side that changed, and that side
differs by operation: a fetch names the B<local> destination the refspec
mapped to, a push names the ref as the B<remote> calls it. That asymmetry
is the semantics of the underlying libgit2 callbacks (C<update_tips> fires
after the local ref is written, C<push_update_reference> relays the
server's own report) and is deliberately left alone.

C<to> is the OID the ref now points at, or C<undef> when the ref was
B<deleted> rather than moved — a stale mirror ref dropped by a
C<< prune => 1 >> fetch, or a delete refspec on a push. On a push it is
read off the local source side of the refspec, not from the server, and is
therefore also C<undef> for a source that is not a resolvable local
reference.

C<from> is the OID the ref pointed at before. It is C<undef> when the ref
did not exist on the receiving side yet, and always C<undef> on a push:
the previous remote-side OID would take a ref listing before the push, and
L<Git::Native::Remote/push> does not spend an extra network round trip on
it. Call L<Git::Native::Remote/list_refs> first if you need that snapshot.

C<reason> is the empty string on every C<updated> entry — a non-empty
reason means the ref was refused, and refused refs are in L</rejected>
instead. Refs that were already up to date are not reported at all.

=head2 rejected

  die "push refused: $_->{ref}: $_->{reason}" for @{ $result->rejected };

Arrayref of C<< { ref => $name, reason => $message } >>, one per ref the
server refused, with C<reason> the status string it sent (C<non-fast-forward>,
C<pre-receive hook declined>, ...). Refused refs never carry an empty
reason — an empty status is libgit2's "accepted, nothing to say" and lands
in L</updated>.

Only a push can populate this. A fetch leaves it empty even when libgit2
skipped a non-fast-forward ref, because that path does not reach the
C<update_tips> callback; on a fetch, a skipped ref shows up as a missing
entry in L</updated>.

=head2 ok

  $result->ok    # 1 when nothing at all happened

True iff both C<updated> and C<rejected> are empty, i.e. the operation
moved no ref and no ref was refused. A fully successful push of N refs
reports all N in C<updated> and is therefore B<not> C<ok> — the check for
"did anything go wrong" is C<< @{ $result->rejected } >>, and C<ok> answers
the different question "was this a no-op?".

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-git-native/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
