package Exobrain::Agent::HabitRPG::Sink;
use Method::Signatures;
use Moose;

with 'Exobrain::Agent::HabitRPG';
with 'Exobrain::Agent::Run';

# ABSTRACT: Send personal log events to iDoneThis
our $VERSION = '0.01'; # VERSION

method run() {
    $self->exobrain->watch_loop(
        class => 'Intent::HabitRPG',
        then  => sub {
            my $event = shift;
            my $hrpg  = $self->habitrpg;

            my $task      = $event->task;
            my $direction = $event->direction;

            my $stats = $hrpg->user->{stats};

            my $result = $hrpg->updown($task, $direction);

            my $name = $hrpg->get_task($task)->{text};

            my $msg;

            if ($direction eq "up") {
                $msg = sprintf(
                    "Congrats! You gained %+.2f XP and %+.2f GP for completing: $name",
                    $result->{exp} - $stats->{exp},
                    $result->{gp}  - $stats->{gp},
                );
            }
            else {
                # Must be down
                $msg = sprintf(
                    "Oh no! You lost %+.2f HP for: $name",
                    $result->{hp} - $stats->{hp},
                )
            }

            $event->exobrain->notify($msg);
        }
    );
}

1;

__END__

=pod

=head1 NAME

Exobrain::Agent::HabitRPG::Sink - Send personal log events to iDoneThis

=head1 VERSION

version 0.01

=head1 AUTHOR

Paul Fenwick <pjf@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Paul Fenwick.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
