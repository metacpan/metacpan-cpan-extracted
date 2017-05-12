package Gesture::Simple;
use Any::Moose;
use 5.008001;

use Gesture::Simple::Gesture;
use Gesture::Simple::Template;

our $VERSION = '0.01';

use constant gesture_class => 'Gesture::Simple::Gesture';

has templates => (
    is         => 'ro',
    isa        => 'ArrayRef',
    default    => sub { [] },
    auto_deref => 1,
);

sub has_templates { @{ shift->templates } > 0 }

sub add_template {
    my $self = shift;

    for (@_) {
        blessed($_) && $_->isa('Gesture::Simple::Template')
            or confess "$_ is not a Gesture::Simple::Template.";
    }

    push @{ $self->templates }, @_;
}

sub match {
    my $self    = shift;
    my $gesture = shift;

    confess "You have no templates to match against!"
        unless $self->has_templates;

    $gesture = $self->gesture_class->new(points => $gesture)
        if !blessed($gesture);

    my @matches = sort { $b->score <=> $a->score }
                  map { $_->match($gesture) }
                  $self->templates;

    return @matches if wantarray;
    return $matches[0];
}

__PACKAGE__->meta->make_immutable;
no Any::Moose;

1;

__END__

=head1 NAME

Gesture::Simple - the $1 (mouse) gesture recognizer

=head1 SYNOPSIS

    my $recognizer = Gesture::Simple->new;

    my @points = read_mouse_coordinates();
    my $gesture = Gesture::Simple::Gesture->new(
        points => \@points,
    );

    my $match = $recognizer->match($gesture);
    if ($match) {
        print $match->template->name;
    }
    else {
        $recognizer->add_template(
            Gesture::Simple::Template->new(
                points => \@points,
                name   => readline(),
            ),
        );
    }

=head1 AUTHOR

Shawn M Moore, C<sartak@gmail.com>

=head1 WARNING

This module is alpha quality. Use it at your own risk.

=head1 SEE ALSO

L<http://faculty.washington.edu/wobbrock/pubs/uist-07.1.pdf> - Paper describing
the algorithm

L<http://depts.washington.edu/aimgroup/proj/dollar/> - Javascript example of
the algorithm

=head1 COPYRIGHT AND LICENSE

Copyright 2009 Shawn M Moore.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

