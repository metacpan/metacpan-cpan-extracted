package Games::2048::Animation;
use 5.012;
use Moo;

use POSIX qw/floor ceil/;

has cur_frame   => is => 'rw', default => 0;
has duration    => is => 'rw', default => 0;
has first_value => is => 'rw', default => 0;
has last_value  => is => 'rw', default => 1;

sub value {
	my $self = shift;
	my $value = $self->cur_frame / ($self->frame_count - 1);
	my $range = $self->last_value - $self->first_value;
	return $value * $range + $self->first_value;
}

sub update {
	my $self = shift;
	return if $self->cur_frame >= $self->frame_count;
	$self->cur_frame($self->cur_frame + 1);
	return 1;
}

sub frame_count {
	my $self = shift;
	return floor($self->duration / Games::2048::FRAME_TIME);
}

1;
