package LibTmux::X;
use v5.44;
use overload '""' => sub ($self, @) {
    my $path = defined $self->{path} ? " at $self->{path}" : '';
    return ref($self) . $path . ': ' . ($self->{message} // 'operation failed');
    },
    fallback => 1;
sub new         ($class, %details) { bless \%details, $class }
sub throw       ($class, %details) { die $class->new(%details) }
sub message     ($self)            { $self->{message} }
sub path        ($self)            { $self->{path} }
sub entity      ($self)            { $self->{entity} }
sub expected    ($self)            { $self->{expected} }
sub received    ($self)            { $self->{received} }
sub matched_ids ($self)            { [($self->{matched_ids} // [])->@*] }
sub count       ($self)            { $self->{count} }
sub result      ($self)            { $self->{result} }
sub dispatched  ($self)            { $self->{dispatched} }
sub details     ($self)            { +{%$self} }

package LibTmux::X::InvalidArgument { use parent -norequire, 'LibTmux::X' }

package LibTmux::X::InvalidSelection { use parent -norequire, 'LibTmux::X' }

package LibTmux::X::InvalidFilter { use parent -norequire, 'LibTmux::X' }

package LibTmux::X::NoMatch { use parent -norequire, 'LibTmux::X' }

package LibTmux::X::MultipleMatches { use parent -norequire, 'LibTmux::X' }

package LibTmux::X::Unloaded { use parent -norequire, 'LibTmux::X' }

package LibTmux::X::UnsupportedValue { use parent -norequire, 'LibTmux::X' }

package LibTmux::X::Unsupported { use parent -norequire, 'LibTmux::X' }

package LibTmux::X::Spawn { use parent -norequire, 'LibTmux::X' }

package LibTmux::X::Timeout { use parent -norequire, 'LibTmux::X' }

package LibTmux::X::Cancelled { use parent -norequire, 'LibTmux::X' }

package LibTmux::X::OutputLimit { use parent -norequire, 'LibTmux::X' }

package LibTmux::X::Transport { use parent -norequire, 'LibTmux::X' }

package LibTmux::X::Codec { use parent -norequire, 'LibTmux::X' }

package LibTmux::X::Command { use parent -norequire, 'LibTmux::X' }

package LibTmux::X::NoServer { use parent -norequire, 'LibTmux::X' }

package LibTmux::X::StaleReference { use parent -norequire, 'LibTmux::X' }

package LibTmux::X::AcquisitionRace { use parent -norequire, 'LibTmux::X' }

package LibTmux::X::QueryMismatch { use parent -norequire, 'LibTmux::X' }

package LibTmux::X::Creation {
    use parent -norequire, 'LibTmux::X';
    sub created ($self) { $self->{created} }
    sub cause   ($self) { $self->{cause} }
}

package LibTmux::X::NoSuchTarget { use parent -norequire, 'LibTmux::X' }

=head1 NAME

LibTmux::X - Typed failures with readable diagnostics

=head1 DESCRIPTION

Errors stringify with class, path, and message. L</Creation> retains its
original acquisition exception separately through C<cause>. C<details> returns
diagnostic fields. Acquisition failures never represent an empty selection.

=head1 METHODS

=head2 new

C<new(%details)> constructs an exception object without throwing or I/O.

=head2 throw

C<throw(%details)> throws one exception object of the receiving class.

=head2 message

Return the human-readable failure description.

=head2 path

Return the criterion or argument path, or undef when inapplicable.

=head2 entity

Return the entity kind, or undef when inapplicable.

=head2 expected

Return the expected operand description, or undef.

=head2 received

Return the received operand description, or undef.

=head2 matched_ids

Return a fresh arrayref of observed matching IDs, including duplicate occurrences.

=head2 count

Return the observed cardinality lower bound where applicable.

=head2 result

Return a completed or bounded partial L<LibTmux::CommandResult>, or undef before process dispatch.

=head2 dispatched

Return whether the request was submitted where known; undef means no dispatch evidence was recorded. This never proves rollback.

=head2 details

Return a fresh shallow hashref of diagnostic fields. Causes and entity handles retain their identity.

=head2 created

Creation failures expose a minimal generation-scoped entity receipt, or undef. Only L<LibTmux::X/Creation> provides this method.

=head2 cause

Return the original acquisition exception for L<LibTmux::X/Creation>.

=head1 CARDINALITY AND DATA FAILURES

=head2 NoMatch

No occurrence matched one().

=head2 MultipleMatches

At least two occurrences matched. matched_ids preserves occurrence diagnostics.

=head2 InvalidFilter

Invalid criteria data; path, expected, and received describe the boundary.

=head2 InvalidSelection

Undefined, hole, wrong-kind, or incompatible-generation membership.

=head2 InvalidArgument

Invalid operation or transport argument before dispatch.

=head2 Unloaded

A required field or relation is not available in captured data.

=head2 UnsupportedValue

A local value has no supported portable wire representation.

=head2 Unsupported

A daemon or execution capability is unavailable.

=head2 AcquisitionRace

Observed generations or topology changed during capture.

=head2 QueryMismatch

Native candidates disagree with captured local matches, or an expert native
query returned an uncaptured ID. C<details-E<gt>{verification}> contains the
detached L<LibTmux::Server/VERIFICATION REPORT>. The cause may be concurrent
change, a translation defect or backend semantics; the comparison does not
identify it. L<LibTmux::Server/query_panes> throws this for require or expert
queries, while auto reports fallback through its optional observer.

=head2 StaleReference

A captured generation or contextual target no longer identifies the same resource.

=head2 Spawn

The executable could not start; dispatch is distinguished from command failure.

=head2 NoServer

The selected server cannot be reached.

=head2 Command

tmux reported nonzero status; result retains stdout/stderr/status.

=head2 Timeout

Execution exceeded its deadline; effects may already have occurred.

=head2 Cancelled

Execution was cancelled; cancellation does not roll back effects.

=head2 OutputLimit

Retained process output exceeded the configured bound.

=head2 Transport

Process supervision or result framing failed.

=head2 Codec

A tmux record or field could not be decoded.

=head2 NoSuchTarget

The selected stable target no longer exists. Native result diagnostics are
retained. This differs from a stale generation and from an arbitrary command
failure; acquire a new snapshot before choosing recovery.

=head2 Creation

A creation command succeeded but subsequent receipt decoding or capture failed.
C<created> returns a minimal generation-scoped entity handle when the command's
receipt was decoded; other fields remain unloaded. C<cause> preserves the
original acquisition failure. C<dispatched> is true. The returned handle permits
explicit, generation-checked cleanup; absent receipts leave effects uncertain.
See L<LibTmux::Server/new_session>.

=head1 DIAGNOSTICS

C<message>, C<path>, C<entity>, C<expected>, C<received>, C<matched_ids>,
C<count>, C<result>, C<dispatched>, and C<details> expose applicable fields.
See L<LibTmux::Selection/one>, L<LibTmux::Filter/new>, and
L<LibTmux::Server> for failure boundaries.

=cut
