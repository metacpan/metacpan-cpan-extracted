package Graph::Layout::Aesthetic::Monitor::GnuPlot;
use 5.006001;
use strict;
use warnings;
use Carp;

our $VERSION = '0.02';
our @CARP_NOT = qw(package Graph::Layout::Aesthetic);

our @gnu_plot = $^O eq "MSWin32" ? 
    qw(pgnuplot) : qw(gnuplot -geometry 600x700-1+1);
# our @gnu_plot = qw(tee blub);
our $margin = 0.05;
our $init_config = ($^O eq "MSWin32" ? "set terminal windows" : "set terminal X11") . "
set data style linespoints
set offsets 0.1, 0.1, 0.1, 0.1
set nokey
set clip two
";

sub new {
    my ($class, %params) = @_;
    my $after_plot = delete $params{after_plot};
    croak "Unknown parameter ", join(", ", keys %params) if %params;

    my $fh;
    if ($^O eq "MSWin32") {
        local $" = " ";	# " unconfuse emacs
        open($fh, "|-", "@gnu_plot") || 
            croak "Could not start $gnu_plot[0]: $!";
    } else {
        no warnings 'exec';
        open($fh, "|-", @gnu_plot) || 
            croak "Could not start $gnu_plot[0]: $!";
    }
    my $old = select($fh);
    eval {
        local $| = 1;
        print($init_config) || croak "Error writing to $gnu_plot[0] pipe: $!";
    };
    select($old);
    die $@ if $@;

    return bless {
        program => $gnu_plot[0],
        fh => $fh,
        after_plot => $after_plot,
        start_time => time,
    }, $class;
}

sub command {
    my $monitor = shift;
    my $fh = $monitor->{fh};
    print($fh @_, "\n") ||
        croak "Error writing to $monitor->{program} pipe: $!";
}

sub commandf {
    my $monitor = shift;
    my $fh = $monitor->{fh};
    printf($fh shift() . "\n", @_) ||
        croak "Error writing to $monitor->{program} pipe: $!";
}

sub command_flush {
    my $monitor = shift;
    my $fh = select($monitor->{fh});
    eval {
        local $| = 1;
        print(@_, "\n") ||
            croak "Error writing to $monitor->{program} pipe: $!";
    };
    select($fh);
    die $@ if $@;
}

sub plot {
    my ($monitor, $aglo) = @_;

    my ($min, $max) = $aglo->iso_frame;
    @$min == 2 || @$min == 3 ||
        croak "Space is ", scalar @$min, "-dimensional (gnuplot display only work in 2 or 3 dimensions)";
    my $edge = ($max->[0]-$min->[0]) * $margin;
    $edge = 1 if $edge == 0;

    my @coordinates = $aglo->all_coordinates;
    my $fh = $monitor->{"fh"};
    printf($fh "set xrange [ %f : %f ]\n", $min->[0]-$edge, $max->[0]+$edge) ||
        croak  "Error writing to $monitor->{program} pipe: $!";
    printf($fh "set yrange [ %f : %f ]\n", $min->[1]-$edge, $max->[1]+$edge) ||
        croak  "Error writing to $monitor->{program} pipe: $!";
    printf($fh "set zrange [ %f : %f ]\n", $min->[2]-$edge, $max->[2]+$edge) ||
        croak  "Error writing to $monitor->{program} pipe: $!" if @$min == 3;
    printf($fh "set title \"Time=%u    Temp=%.3f\"\n",
           time() - $monitor->{start_time}, $aglo->temperature) ||
               croak  "Error writing to $monitor->{program} pipe: $!";
    print($fh "plot \"-\"\n") || croak "Error writing to $monitor->{program} pipe: $!";
    for ($aglo->topology->edges) {
        print($fh "@$_\n") || croak "Error writing to $monitor->{program} pipe: $!" for
            @coordinates[@$_];
        print($fh "\n") || croak "Error writing to $monitor->{program} pipe: $!";
    }
    $monitor->command_flush("e");
    $monitor->{last_plot} = time;
    $monitor->{after_plot}->($aglo, $monitor) if $monitor->{after_plot};
}

sub last_plot_time {
    return shift->{last_plot};
}

sub DESTROY {
    my $monitor = shift;
    my $fh = $monitor->{"fh"};
    print $fh "quit\n";
    close($fh);
    warn("Unexpected returncode from gnuplot: $?") if $?;
}

__END__

=head1 NAME

Graph::Layout::Aesthetic::Monitor::GnuPlot - Display progress of a graph layout using gnuplot

=head1 SYNOPSIS

    use Graph::Layout::Aesthetic::Monitor::GnuPlot;
    $monitor = Graph::Layout::Aesthetic::Monitor::GnuPlot->new(%parameters);

    # Now use it with Graph::Layout::Aesthetic object $aglo:
    $aglo->gloss(monitor => $monitor);

    # That's the basics. You likely won't need the stuff after this point
    $monitor->plot($aglo);
    $monitor->command($command);
    $monitor->command_flush($command);
    $monitor->commandf($format, @arguments);
    $time = $monitor->last_plot_time;

=head1 DESCRIPTION

Graph::Layout::Aesthetic::Monitor::GnuPlot is a simple class based on
L<gnuplot|gnuplot(1)> that is meant to help you to monitor the progress of
a graph layout. It has the right interface so it can be directly used as
the value of the L<monitor|Graph::Layout::Aesthetic/gloss_monitor> parameter
to L<Graph::Layout::Aesthetic method gloss|Graph::Layout::Aesthetic/gloss>.

=head1 METHODS

=over

=item X<new>$monitor = Graph::Layout::Aesthetic::Monitor::GnuPlot->new(%parameters)

Creates a new Graph::Layout::Aesthetic::Monitor::GnuPlot object. The parameters
are name/value pairs which currently can be:

=over

=item X<new_after_plot>after_plot => $callback

Whenever the L<plot|"plot"> method is called, this callback is also executed
after flushing the actual plot commands to L<gnuplot|gnuplot(1)> like this:

    $callback->($aglo, $monitor);

Unless $callback is false (the default) in which case nothing gets done.

=back

=item X<plot>$monitor->plot($aglo)

Takes the current L<Graph::Layout::Aesthetic|Graph::Layout::Aesthetic> $aglo
state and plots it. At the end of this call the L<after_plot|"new_after_plot">
callback is done if any was given.

This method usually gets called implicitly by the
L<Graph::Layout::Aesthetic method gloss|Graph::Layout::Aesthetic/gloss>.

=item X<command>$monitor->command($command)

Sends $command directly to L<gnuplot|gnuplot(1)>. Since no flush on the
controlling pipe is done the command may (or may not) get buffered and
therefore not executed until something flushes it. See
L<command_flush|"command_flush">.

A newline gets appended to the $command internally.

=item X<command_flush>$monitor->command_flush($command)

The same as L<command|"command">, but also flushes the controlling pipe to
L<gnuplot|gnuplot(1)>. So all already buffered commands and this command will
get executed.

=item X<commandf>$monitor->commandf($format, @arguments)

The same as L<command|"command">, but with a L<printf|perlfunc/printf> style
interface.

=item X<last_plot_time>$time = $monitor->last_plot_time

Return the epoch time of the last time a L<plot|"plot"> method call returned.
Returns undef if a L<plot|"plot"> has never been done yet.

=back

=head1 EXPORTS

None.

=head1 SEE ALSO

L<Graph::Layout::Aesthetic>,
L<gnuplot(1)>

=head1 AUTHOR

Ton Hospel, E<lt>Graph-Layout-Aesthetic@ton.iguana.beE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Ton Hospel

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.6.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
