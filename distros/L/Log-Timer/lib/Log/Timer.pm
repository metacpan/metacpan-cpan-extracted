package Log::Timer;

use strict;
use warnings;
use Exporter 'import';
our $VERSION = '1.0.1'; # VERSION
# ABSTRACT: track nested timing information


our @EXPORT = our @EXPORT_OK = qw/ timer subroutine_timer /;

use Guard::Timer;
use List::AllUtils qw/ max /;
use Statistics::Descriptive;
use Log::Any qw/ $log /;


my $name__context = {
    "" => {
        indent => 1,
    },
};
my $message_stats = {};


sub timer {
    my ($message, $options) = @_;
    $options //= {};

    my $log_prefix = $options->{prefix} // "";

    # If you run async code, you need to distinguish the context this
    # is running in. Human readable.
    my $context_name = $options->{context} //= "";

    # Create context at the same level we're at, assuming we're always
    # branching off the default "process wide" context
    my $context = $name__context->{ $context_name } //= {
        start_indent => $name__context->{ "" }->{indent},
        %{ $name__context->{ "" } },
    };

    my $indent_increase = $options->{indent_increase} // 4;

    $context->{indent} += $indent_increase;

    my $context_prefix = $context_name eq ""
        ? ""
        : "$context_name: ";

    return timer_guard(
        sub {
            my $duration = shift;
            _collect_timing($message, $duration);

            # Un-nest indentation level
            my $indent = $context->{indent} -= $indent_increase;

            my $indentation = " " x max(1, $indent);
            $log->trace("${log_prefix}duration($duration)$indentation$context_prefix$message");

            # Clean up context if we're done with it
            if(my $start_indent = $context->{start_indent}) {
                if( $indent == $start_indent ) {
                    delete $name__context->{ $context_name };
                }
            }
        },
        4, # decimal points
    );
}


sub subroutine_timer {
    my ($message, $options) = @_;
    $options //= {};

    my $depth = $options->{depth} || 1;
    my (undef, undef, undef, $subroutine) = caller($depth);
    $subroutine =~ s/::(\w+)$/->$1/;
    $message = defined($message) ? ": $message" : "";

    return timer( "$subroutine$message", $options );
}

sub _collect_timing {
    my ($message, $duration) = @_;
    my $stats = $message_stats->{$message} ||= Statistics::Descriptive::Sparse->new();
    $stats->add_data($duration);
}


sub report_timing_stats {
    my @what = ( "mean", "sum", "min", "max", "standard_deviation" );

    my @messages =
        map  { $_->{message} }
        reverse
        sort { $a->{order} <=> $b->{order} }
        map  {
            my $stats = $message_stats->{$_};
            +{
                message => "Stats: "
                    . sprintf("%-12s", "count(" . $stats->count . "), ")
                    . join(
                        ", ",
                        map { sprintf("$_(%.3f)", ($stats->$_)) } @what
                    ) . " for ($_)",
                order => $stats->sum,
            };
        }
        keys %$message_stats;

    for my $message (@messages) {
        $log->info($message);
    }

    clear_timing_stats();
}


sub clear_timing_stats {
    $message_stats = {};
}

END {
    report_timing_stats();
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Timer - track nested timing information

=head1 VERSION

version 1.0.1

=head1 SYNOPSIS

  use Log::Timer;

  sub some_action {
      my $sub_timer = subroutine_timer();
      # do things
      ...
  }

=head1 FUNCTIONS

=head2 C<timer>

  my $timer1 = timer('GET /foo');
  my $timer2 = timer('update_all_things');
  my $timer3 = timer('fetching data from DB', {
                   prefix  => $request_url,
                   context => $request_id,
               });

Start a timer. When the returned object gets destroyed, logs the time
elapsed (at C<trace> level).

All timers with the same C<$message> contribute to a set of stats, see
C<report_timing_stats>

The C<prefix> is just added in front of the log message.

Timers started "inside" other timers will get logged indented, so that
you can see the breakdown of any outer timings. If you need to capture
several timer metrics at the same level, you can pass C<<
indent_increase => 0 >> after the first timer.

If you're running a set of asynchronous tasks, using the same
C<context> for each logical task (using for example a request id) will
ensure that the nested indenting makes sense.

=head2 C<subroutine_timer>

  my $timer1 = subroutine_timer();
  my $timer2 = subroutine_timer($message, {
                   prefix  => $request_url,
                   context => $request_id,
                   depth   => 2,
               });

Same as L<< /C<timer> >>, but the C<$message> is automatically
prefixed with the name of the current subroutine. You can pass a
C<depth> option (defaults to 1) to pick a sub further up the call
stack.

=head2 C<report_timing_stats>

   Log::Timer::report_timing_stats();

Logs (at C<info> level) some statistical information about the timers
ran until now, grouped by message. Then clears the stored values.

This is also called automatically at C<END> time.

=head2 C<clear_timing_stats>

   Log::Timer::clear_timing_stats();

Clears all values stored for statistical purposes.

=head1 AUTHORS

=over 4

=item *

Johan Lindstrom <Johan.Lindstrom@broadbean.com>

=item *

Gianni Ceccarelli <gianni.ceccarelli@broadbean.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by BroadBean UK, a CareerBuilder Company.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
