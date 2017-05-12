package Games::FrogJump::Animation;
use 5.012;

use Moo;

has name          => is => 'rw', default => '';
has current_frame => is => 'rw', default => 0;
has duration      => is => 'rw', default => 0;
has obj           => is => 'rw', default => '';
has attr          => is => 'rw', default => '';
has snapshot      => is => 'rw', default => '';

sub frame_count {
    my $self = shift;
    return int($self->duration / $Games::FrogJump::FRAME_TIME);
}

sub snapshot_frame_count {
    my $self = shift;
    return int($self->frame_count / @{$self->snapshot});
}

sub end {
    my $self = shift;
    return $self->current_frame >= $self->frame_count ? 1 : 0;
}

sub update {
    my $self = shift;
    my $obj  = $self->obj;
    my $attr = $self->attr;
    my $snap_index = int($self->current_frame / $self->snapshot_frame_count);
    $obj->$attr($self->snapshot->[$snap_index]) if $snap_index < @{$self->snapshot};
    $self->current_frame($self->current_frame + 1);
}
1;
