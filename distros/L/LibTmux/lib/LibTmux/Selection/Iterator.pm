package LibTmux::Selection::Iterator;
use v5.44;

sub next ($self) {
    return undef if $self->{next} >= $self->{items}->@*;
    return $self->{items}[$self->{next}++];
}

=head1 NAME

LibTmux::Selection::Iterator - Local cursor over frozen membership

=head1 METHODS

=head2 next

Return the next captured entity or undef only at exhaustion. Order and
multiplicity match creation-time membership. Later native selection edits do
not change this traversal. A cursor is consumable; create a fresh cursor with
L<LibTmux::Selection/iterator> to traverse again. No tmux I/O occurs.

=cut
