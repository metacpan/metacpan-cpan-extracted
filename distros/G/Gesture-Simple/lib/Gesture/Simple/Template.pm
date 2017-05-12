package Gesture::Simple::Template;
use Any::Moose;
extends 'Gesture::Simple::Gesture';
use Scalar::Defer qw/defer force/;

use Gesture::Simple::Match;

use constant match_class => 'Gesture::Simple::Match';

has name => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

sub match {
    my $self    = shift;
    my $gesture = shift;

    my $raw_score = $self->score_match($gesture);

    return $self->match_class->new(
        template => $self,
        gesture  => $gesture,
        score    => $raw_score,
    );
}

sub score_match {
    my $self     = shift;
    my $gesture  = shift;
    my $distance = $self->distance_at_best_angle($gesture);

    my $score = 1 - $distance / (.5 * sqrt(100 ** 2 + 100 ** 2));
    return $score * 100;
}

use constant minimum_angle   => -0.785398163; # -45 degrees
use constant maximum_angle   =>  0.785398163; # 45 degrees
use constant angle_threshold => 0.034906585;  # 2 degrees

sub distance_at_best_angle {
    my $self    = shift;
    my $gesture = shift;

    my $theta_a = $self->minimum_angle;
    my $theta_b = $self->maximum_angle;
    my $threshold = $self->angle_threshold;

    my $phi = .61803399; # golden ratio

    my $x1 = defer {      $phi  * $theta_a + (1 - $phi) * $theta_b };
    my $x2 = defer { (1 - $phi) * $theta_a +      $phi  * $theta_b };

    my $f1 = defer { $self->distance_at_angle($gesture, force $x1) };
    my $f2 = defer { $self->distance_at_angle($gesture, force $x2) };

    while (abs($theta_b - $theta_a) > $threshold) {
        if ($f1 < $f2) {
            $theta_b = force $x2;
        }
        else {
            $theta_a = force $x1;
        }
    }

    return $f1 < $f2 ? $f1 : $f2;
}

sub distance_at_angle {
    my $self    = shift;
    my $gesture = shift;
    my $theta   = shift;

    my $rotated = $gesture->rotate_by($gesture->points, $theta);
    return $self->path_distance($rotated);
}

sub path_distance {
    my $self   = shift;
    my $points = shift;
    my $template = $self->points;

    my $distance = 0;

    for (my $i = 0; $i < @$template; ++$i) {
        my $d = $self->distance($template->[$i], $points->[$i]);
        $distance += $d;
    }

    $distance /= @$template;

    return $distance;
}

__PACKAGE__->meta->make_immutable;
no Any::Moose;

1;

