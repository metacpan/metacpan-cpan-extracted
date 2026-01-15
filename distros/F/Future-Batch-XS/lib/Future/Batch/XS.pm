package Future::Batch::XS;

use 5.014;
use strict;
use warnings;

use Future;
use Exporter 'import';

our $VERSION = '0.02';
our @EXPORT_OK = qw(batch);

require XSLoader;
XSLoader::load('Future::Batch::XS', $VERSION);

1;

__END__

=head1 NAME

Future::Batch::XS - XS implementation of batch processing for Future operations

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

    use Future::Batch::XS qw(batch);
    
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
    my $batch = Future::Batch::XS->new(
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

Future::Batch::XS provides a way to process multiple items through a 
Future returning worker function with controlled concurrency. It ensures
that no more than a specified number of operations run simultaneously,
while maintaining result order matching the input order.

This is the XS implementation of L<Future::Batch>, providing the same
API with improved performance. The entire batch processing loop is
implemented in C/XS, including Future callbacks.

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

    my $batch = Future::Batch::XS->new(%args);

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

=head1 IMPLEMENTATION NOTES

This module creates XS closures for Future's on_done/on_fail callbacks.
Each callback stores its closure data (state reference, item, index) in
a C struct attached to the CV via SV magic (PERL_MAGIC_ext). The callback
data is automatically freed when the CV is garbage collected.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-future-batch-xs at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Future-Batch-XS>.

=head1 SEE ALSO

L<Future::Batch>, L<Future>, L<Future::Utils>, L<Future::Queue>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
