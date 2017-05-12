use strict;
use warnings;
package Functional::Utility;
use base qw(Exporter);

use Time::HiRes ();

our @EXPORT_OK = qw(
  context
  hook_run_hook
  hook_run
  throttle
  y_combinator
);

# most of my modules start at 0.01. This one started at 1.01 because
# I actually use this code in production.
our $VERSION = 1.02;

sub context {
	my ($lookback) = @_;
	my $wa = (caller($lookback || 0))[5];
	return 'VOID' unless defined $wa;
	return 'SCALAR' if !$wa;
	return 'LIST' if $wa;
}

sub hook_run_hook {
	my ($pre, $code, $post) = @_;

	$pre->() if $pre;

	my $callers_context = context(1);
	my @ret;
	+{
	  LIST => sub { @ret = $code->() },
	  SCALAR => sub { $ret[0] = $code->() },
	  VOID => sub { $code->(); return },
	}->{$callers_context}->();

	$post->() if $post;

	return $callers_context eq 'LIST' ? @ret : $ret[0];
}

sub hook_run {
	my (%args) = @_;
	return hook_run_hook(@args{qw(before run after)});
}

{
	my ($delay_time, $nth_run);
	sub throttle_delay (&$) {
		my ($code, $delay) = @_;
		my $delta = Time::HiRes::time - ($delay_time = Time::HiRes::time);
		Time::HiRes::sleep($delay - $delta) if $nth_run && $delay - $delta > 0;
		$nth_run ||= 1;
		$code->();
	}

	my ($ultimate_factor_duration, $penultimate_factor_duration);
	sub throttle_factor (&$) {
		my ($code, $factor) = @_;
		my $start;
		return hook_run_hook(
			sub {
				# If we're about to excute the 3rd or higher run, we can easily calculate how much we need to sleep
				# so the delay between runs is the right $factor.
				my $catchup = (($penultimate_factor_duration || 0) * $factor) - ($ultimate_factor_duration || 0);
				Time::HiRes::sleep($catchup) if $catchup > 0;

				# Are we about to execute the 2nd run? If so, we should sleep a little before executing so the delay
				# between the 1st and 2nd run is the right $factor.
				my $whoa_there_nelly = defined $ultimate_factor_duration && ! defined $penultimate_factor_duration;

				$penultimate_factor_duration = $ultimate_factor_duration;

				if ($whoa_there_nelly) {
					my $catchup = (($penultimate_factor_duration || 0) * $factor) - ($ultimate_factor_duration || 0);
					Time::HiRes::sleep($catchup) if $catchup > 0;
				}

				$start = Time::HiRes::time;
			},
			$code,
			sub {
				$ultimate_factor_duration = Time::HiRes::time - $start;
			},
		);
	}

	sub throttle (&@) {
		my $type = splice @_, 1, 1;
		goto &throttle_delay if $type eq 'delay';
		goto &throttle_factor;
	}
}

sub y_combinator (&) {
	my $curried = shift;
	return sub {
		my $f1 = shift;
		return $curried->(sub { $f1->($f1)(@_) })
	}->(sub {
		my $f2 = shift;
		return $curried->(sub { $f2->($f2)(@_) });
	});
}

1;

__END__

=head1 NAME

Functional::Utility - helper tools for light-weight functional programming.

=head1 SYNOPSIS

Slow down a piece of code, either by delaying $N seconds between runs or by
taking $N times as long in between runs as a single run takes:

    throttle { print scalar(localtime) . "\n" } delay => $N for 1..5;

    throttle { do_something_expensive } factor => $N for 1..5;


Light-weight Moose-style before/after hooks for some arbitrary piece of code:

    hook_run(
	      before => sub { warn "starting up...\n" },
	      run    => $timed_block,
	      after  => sub { warn "...all done!\n" },
    );

Allow an anonymous function to be self-recursive without leaking memory:

    y_combinator {
        my ($recursive_function) = @_;

        return sub {
             # ... do work ...

             $recursive_function->() if some_condition;
             return;
        };
    };

=head1 DESCRIPTION

Functional::Utility provides a small collection of utilities to make certain pieces
of functional programming a bit easier. Included are a few tools for controlling the
behavior of existing functions.

=head1 EXPORTABLE FUNCTIONS

=head2 hook_run_hook PRE_CODEREF, CODEREF, POST_CODEREF

=head2 hook_run before => PRE_CODEREF, run => CODEREF, after => POST_CODEREF

Run PRE_CODEREF, then CODEREF, then POST_CODEREF. The return value of hook_run (and
hook_run_hook) is the return value of CODEREF. CODEREF will be called in the same
context as hook_run itself is called.

To write a light-weight timer function, you might do this:

    sub timing_of (&) {
        my $block_to_time = shift;

        my $start;

        return hook_run(
            before => sub { $start = time },
            run    => $block_to_time,
            after  => sub { warn "code took " . (time - $start) . " seconds to run\n" },
        );
    }

And then if you had some pieces of code such as this:

    my $line = <$fh>;

you could add timing around it by simply saying:

    my $line = timing_of { <$fh> };

Since the return value of timing_of() is the return value of hook_run(), you
could also write this, if you really cared to read an entire file into memory:

    my @lines = <$fh>;

    my @lines = timing_of { <$fh> };

Using hook_run(), you might write some more interesting functions beyond stopwatches:

    sub nytprof_of (&;$) {
        my $profiled_block = shift;
        my $profile_output = shift || 'nytprof.out';

        require Devel::NYTProf;

        return hook_run(
            before => sub { Devel::NYTProf->start_profiling },
            run    => $profiled_block,
            after  => sub { Devel::NYTProf->stop_profiling },
        );
    }

=head2 throttle BLOCK delay => N

Run BLOCK, sleeping N seconds between runs.

=head2 throttle BLOCK factor => N

Run BLOCK and time it, and then wait N times as long between runs as the code takes
to run.

In order to prevent replication lag between our master/slave database setup, our DBAs
request that we limit our inserts to 1,000 at a time and sleep 4 times as long between
inserts as the inserts take to run.

I use

    throttle { my @binds = @{shift @args};  $sth->execute(@binds) } factor => 4
        while @args;

to manage the waiting; @args and $sth are built to accomodate 1,000 entries at a
time.

=head2 y_combinator BLOCK

My short-sighted view of y_combinator is that it allows you to create a recursive
anonymous subroutine in Perl without leaking memory.

Here's a naive recursive anonymous subroutine:

    my $factorial;
    $factorial = sub {
        my $n = shift;
        return $n if $n == 1;
        return $n * $factorial->($n - 1);
    };

    my $factorial_6 = $factorial->(6);

If you're committed to using recursive anonymous subroutines in your design, and
if you're on a version of perl lower than 5.16 (which introduces the __SUB__ token),
then the y_combinator may be just what you need.

    my $factorial = y_combinator {
        my ($recurse) = @_;

        return sub {
            my $n = shift;
            return $n if $n == 1;
            return $n * $recurse->($n - 1);
        };
    };

    my $factorial_6 = $factorial->(6);

For a much stronger treatment of the whats and whys of y_combinator(), view any of
the excellent tutorials on this subject; I like http://mvanier.livejournal.com/2897.html

=head1 BUGS AND LIMITATIONS

The timing_of() function provided in the examples for hook_run() is a bit deceptive,
because it ends up timing the overhead of hook_run() in addition to the piece of
code being timed. However, if you're timing multiple pieces of code, the overhead of
hook_run() will work out to be the same in all cases, at which point the deception
is moot.

Currently, two pieces of code may not be throttled at the same time.

Please report any bugs or feature requests to this project's Github page:
L<http://github.com/belden/perl-functional-utility/issues>.

=head1 A NOTE ON CONTRIBUTING

This is a growing collection. You may contribute your own functional utilities via this
project's Github page: L<http://github.com/belden/perl-functional-utility>.

=head1 COPYRIGHT AND LICENSE

    (c) 2013 by Belden Lyman

This library is free software: you may redistribute it and/or modify it under the same terms as Perl
itself; either Perl version 5.8.8 or, at your option, any later version of Perl 5 you may have
available.
