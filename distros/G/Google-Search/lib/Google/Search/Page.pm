package Google::Search::Page;

use Any::Moose;
use Google::Search::Carp;

has search => qw/ is ro required 1 isa Google::Search /;
has number => qw/ is ro required 1 isa Int /;

has response => qw/ is ro lazy_build 1 /, handles => [qw/ http_response results error /];
sub _build_response {
    my $self = shift;
    return $self->search->request( start => $self->start );
}

has start => qw/ is ro lazy_build 1 isa Int /;
sub _build_start {
    my $self = shift;
    return $self->number * $self->search->rsz2number;
}

sub result {
    my $self = shift;
    my $number = shift;

    return if $self->error;

    return unless $self->results;

    return $self->results->[$number];
}

1;
