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
# updated entries: { ref => $name, from => $from_oid_hex_or_undef, to => $to_oid_hex }
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

version 0.004

=head1 SYNOPSIS

  my $r = $remote->fetch(
    refspecs => ['+refs/heads/*:refs/remotes/origin/*'],
  );
  if ( !$r->ok ) {
    for my $u ( @{ $r->updated } ) {
      warn "updated $u->{ref}: $u->{from} // $u->{to}\n";
    }
    for my $u ( @{ $r->rejected } ) {
      warn "rejected $u->{ref}: $u->{reason}\n";
    }
  }

=head1 DESCRIPTION

Structured return value from L<Git::Native::Remote>'s C<fetch> and C<push>.
See L</updated>, L</rejected>, and L</ok>.

=head2 updated

  Arrayref of hashrefs, one per ref that was actually moved.
  Each entry: C<< { ref => $str, from => $oid_hex|undef, to => $oid_hex } >>.
  C<from> is C<undef> for refs that didn't exist on the local side before the
  operation (a brand-new branch fetched or pushed). On a push, C<from> is
  always the local tip the ref was moving from (i.e. C<undef> when pushing
  a brand-new ref that the remote didn't have).

=head2 rejected

  Arrayref of hashrefs, one per ref that the server refused to accept.
  Each entry: C<< { ref => $str, reason => $str } >>. C<reason> is the
  libgit2 / server message; C<""> (empty) when the server reported a
  rejection with no specific text. On a successful push, C<rejected> is
  empty (the successful refs are in C<updated>).

=head2 ok

  True iff both C<updated> and C<rejected> are empty. Note that a
  fully-successful push still reports its refs in C<updated> (so C<ok>
  is false) — the typical "did anything go wrong" check is
  C<< !$r->rejected >>.

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
