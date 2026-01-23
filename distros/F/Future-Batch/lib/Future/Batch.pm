package Future::Batch;

use 5.010;
use strict;
use warnings;

use Future;
use Exporter 'import';

our $VERSION = '0.02';
our @EXPORT_OK = qw(batch);

sub new {
    my ($class, %args) = @_;
    bless {
        concurrent  => $args{concurrent}  // 10,
        fail_fast   => $args{fail_fast}   // 0,
        on_progress => $args{on_progress},
        loop        => $args{loop},
    }, $class;
}

sub concurrent  { $_[0]->{concurrent} }
sub fail_fast   { $_[0]->{fail_fast} }
sub on_progress { $_[0]->{on_progress} }
sub loop        { $_[0]->{loop} }

sub run {
    my ($self, %args) = @_;

    my $items  = $args{items}  // [];
    my $worker = $args{worker} // sub { Future->done($_[0]) };

    return Future->done([]) unless @$items;

    my $total       = @$items;
    my $concurrent  = $self->concurrent;
    my $fail_fast   = $self->fail_fast;
    my $on_progress = $self->on_progress;
    my $loop        = $self->{loop};

    my @results = (undef) x $total;
    my @queue   = 0 .. $#$items;
    my @errors;
    my $in_flight = 0;
    my $finished  = 0;

    my $result_future = Future->new;

    my $start_one;
    $start_one = sub {
        return if $result_future->is_ready;
        return unless @queue && $in_flight < $concurrent;

        my $idx  = shift @queue;
        my $item = $items->[$idx];
        $in_flight++;

        my $f = eval { $worker->($item, $idx) };
        if ($@) {
            $f = Future->fail($@);
        } elsif (!defined $f || !ref($f) || !$f->isa('Future')) {
            $f = Future->done($f);
        }

        $f->on_done(sub {
            $results[$idx] = @_ == 1 ? $_[0] : \@_;
            $in_flight--;
            $finished++;
            $on_progress->($finished, $total) if $on_progress;

            $finished == $total
                ? _finish($result_future, \@errors, \@results)
                : $self->_schedule($start_one);
        });

        $f->on_fail(sub {
            my @failure = @_;
            $in_flight--;
            $finished++;
            push @errors, { index => $idx, item => $item, failure => \@failure };
            $on_progress->($finished, $total) if $on_progress;

            if ($fail_fast) {
                @queue = ();
                $result_future->fail(
                    "Batch aborted: " . ($failure[0] // 'unknown error'),
                    batch => \@errors, \@results
                );
            } elsif ($finished == $total) {
                _finish($result_future, \@errors, \@results);
            } else {
                $self->_schedule($start_one);
            }
        });
    };

    # Fill initial concurrent slots
    if ($loop) {
        $start_one->();
        $loop->later($start_one) for 1 .. min($concurrent - 1, scalar @queue);
    } else {
        $start_one->() while @queue && $in_flight < $concurrent;
    }

    return $result_future;
}

sub min { $_[0] < $_[1] ? $_[0] : $_[1] }

sub batch {
    my (%args) = @_;
    __PACKAGE__->new(
        concurrent  => delete $args{concurrent}  // 10,
        fail_fast   => delete $args{fail_fast}   // 0,
        on_progress => delete $args{on_progress},
        loop        => delete $args{loop},
    )->run(%args);
}

sub _schedule {
    my ($self, $code) = @_;
    my $loop = $self->{loop};
    $loop ? $loop->later($code) : $code->();
}

sub _finish {
    my ($result_future, $errors, $results) = @_;
    if (@$errors) {
        my $count = @$errors;
        $result_future->fail("Batch failed with $count error(s)", batch => $errors, $results);
    } else {
        $result_future->done($results);
    }
}


1;

__END__

=head1 NAME

Future::Batch - Process multiple Future-returning operations with concurrency control

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

    use Future::Batch qw(batch);
    
    # Functional interface
    my $results = batch(
        items      => \@urls,
        concurrent => 5,
        worker     => sub {
            my ($url, $index) = @_;
            return $http->GET($url);  # returns a Future
        },
    )->get;
    
    # Object-oriented interface
    my $batch = Future::Batch->new(
        concurrent => 5,
        fail_fast  => 0,
    );
    
    my $future = $batch->run(
        items  => \@items,
        worker => sub { ... },
    );
    
    my $results = $future->get;
    
    # With an event loop (for true non-blocking with immediate futures)
    use IO::Async::Loop;
    my $loop = IO::Async::Loop->new;
    
    my $future = batch(
        items      => \@items,
        concurrent => 5,
        loop       => $loop,
        worker     => sub { ... },
    );
    
    my $results = $loop->await($future);
    
    # With progress tracking
    batch(
        items       => \@items,
        concurrent  => 10,
        on_progress => sub {
            my ($completed, $total) = @_;
            printf "Progress: %d/%d\n", $completed, $total;
        },
        worker => sub { ... },
    )->get;

=head1 DESCRIPTION

Future::Batch provides a way to process multiple items through a 
Future-returning worker function with controlled concurrency. It ensures
that no more than a specified number of operations run simultaneously,
while maintaining result order matching the input order.

This is useful for scenarios like:

=over 4

=item * Fetching multiple URLs with limited concurrent connections

=item * Processing files with bounded parallelism

=item * Rate-limited API calls

=item * Any batch operation where you need to balance throughput with resource usage

=back

=head1 EXPORTS

=head2 batch

    my $future = batch(%args);

Functional interface. Takes the same arguments as C<new()> and C<run()>
combined. Returns a Future that resolves to an arrayref of results.

=head1 METHODS

=head2 new

    my $batch = Future::Batch->new(%args);

Create a new batch processor.

=head3 Arguments

=over 4

=item concurrent => $n

Maximum number of concurrent operations. Default: 10.

=item fail_fast => $bool

If true, abort remaining operations on first failure. Default: false.

=item on_progress => sub { my ($completed, $total) = @_; ... }

Optional callback invoked after each item completes (success or failure).

=item loop => $loop

Optional event loop object (e.g., L<IO::Async::Loop>). When provided, the
batch processor will use C<$loop-E<gt>later()> to schedule starting new
items, yielding to the event loop between items. This ensures non-blocking
behavior even when workers return immediate (already-completed) futures.

Without a loop, immediate futures are processed synchronously, which is
fine for truly async workers that return pending futures.

=back

=head2 run

    my $future = $batch->run(%args);

Execute the batch operation. Returns a Future.

=head3 Arguments

=over 4

=item items => \@items

Arrayref of items to process.

=item worker => sub { my ($item, $index) = @_; return $future; }

Coderef that receives each item and its index, and should return a Future.
If the worker returns a non-Future value, it will be wrapped in 
C<Future-E<gt>done()>. If the worker dies, the error is captured.

=back

=head2 concurrent

    my $n = $batch->concurrent;

Returns the concurrency limit.

=head2 fail_fast

    my $bool = $batch->fail_fast;

Returns the fail_fast setting.

=head2 on_progress

    my $cb = $batch->on_progress;

Returns the progress callback, if set.

=head2 loop

    my $loop = $batch->loop;

Returns the event loop, if set.

=head1 RESULT HANDLING

On success, the returned Future resolves to an arrayref of results in the
same order as the input items.

On failure (when any worker fails and fail_fast is false), the Future fails
with:

    ("Batch failed with N error(s)", "batch", \@errors, \@partial_results)

On failure with fail_fast:

    ("Batch aborted: <error>", "batch", \@errors, \@partial_results)

The C<@errors> arrayref contains hashrefs with:

    { index => $idx, item => $item, failure => \@failure_args }

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-future-batch at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Future-Batch>.

=head1 SEE ALSO

L<Future>, L<Future::Utils>, L<Future::Queue>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
