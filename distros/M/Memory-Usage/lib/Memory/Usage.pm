package Memory::Usage;
use warnings;
use strict;

=head1 NAME

Memory::Usage - Tools to determine actual memory usage

=head1 VERSION

Version 0.201

=cut

our $VERSION = '0.201';


=head1 SYNOPSIS

    use Memory::Usage;
    my $mu = Memory::Usage->new();

    # Record amount of memory used by current process
    $mu->record('starting work');

    # Do the thing you want to measure
    $object->something_memory_intensive();

    # Record amount in use afterwards
    $mu->record('after something_memory_intensive()');

    # Spit out a report
    $mu->dump();


=head1 DESCRIPTION

This module lets you attempt to measure, from your operating system's
perspective, how much memory a process is using at any given time.

=head1 METHODS

=head2 Class Methods

=over 4

=item new ( )

Creates a new Memory::Usage object.  This object will contain usage state as
recorded along the way.

=back

=cut

sub new
{
	my ($class) = @_;

	# TODO: allow pre-sizing of array at construct time so auto-growing
	# doesn't affect memory usage later on.  Probably not a big deal given
	# that our granularity is pages (4k) and our logged messages are small.
	my $self = [];

	return bless $self, $class;
}

# Returns
#  (vsize, rss, shared pages, code pages, data+stack pages)
# in kilobytes.  Precision is to nearest 4k page.
# TODO: Proc::ProcessTable so that we can support non-Linux?
my $page_size_in_kb = 4;
sub _get_mem_data
{
	my ($class, $pid) = @_;

	sysopen(my $fh, "/proc/$pid/statm", 0) or die $!;
	sysread($fh, my $line, 255) or die $!;
	close($fh);
	my ($vsz, $rss, $share, $text, $crap, $data, $crap2) = split(/\s+/, $line,  7);
	return map { $_ * $page_size_in_kb } ($vsz, $rss, $share, $text, $data);
}

=head2 Instance Methods

=over 4

=item record ( $message [, $pid ])

Record the memory usage at call time, logging it internally with the provided
message.  Optionally takes a process ID to record memory usage for, defaulting
to the current process.

=cut

sub record
{
	my ($self, $message, $pid) = @_;

	$pid ||= $$;

	push @$self, [
		time(),
		$message,
		$self->_get_mem_data($pid)
	];
}

=item report ( )

Generates report on memory usage.

=cut

sub report
{
	my ($self) = @_;

	my $report = sprintf "%6s %6s (%6s) %6s (%6s) %6s (%6s) %6s (%6s) %6s (%6s)\n",
		'time',
		'vsz',
		'diff',
		'rss',
		'diff',
		'shared',
		'diff',
		'code',
		'diff',
		'data',
		'diff';

	my $prev = [ undef, undef, 0, 0, 0, 0, 0 ];
	foreach (@$self) {
		$report .= sprintf "% 6d % 6d (% 6d) % 6d (% 6d) % 6d (% 6d) % 6d (% 6d) % 6d (% 6d) %s\n",
			($_->[0] - $self->[0][0]),
			$_->[2],
			($_->[2] - $prev->[2]),
			$_->[3],
			($_->[3] - $prev->[3]),
			$_->[4],
			($_->[4] - $prev->[4]),
			$_->[5],
			($_->[5] - $prev->[5]),
			$_->[6],
			($_->[6] - $prev->[6]),
			$_->[1];
		$prev = $_;
	}

	return $report;
}

=item dump ( )

Prints report on memory usage to stderr.


=cut

sub dump
{
	my ($self) = @_;

	print STDERR $self->report();
}

=item state ( )

Return arrayref of internal state.  Returned arrayref contains zero or more
references to arrays with the following columns (in order).  All sizes are in
kilobytes.

=over 4

=item timestamp (in seconds since epoch)

=item message (as passed to ->record())

=item virtual memory size

=item resident set size

=item shared memory size

=item text (aka code or exe) size

=item data and stack size

=back

=cut

sub state
{
	my ($self) = @_;

	return $self;
}

=pod

=back

=head1 AUTHOR

Dave O'Neill, C<< <dmo at dmo.ca> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-memory-usage at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Memory-Usage>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Memory::Usage

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Memory-Usage>

=item * Search CPAN

L<http://search.cpan.org/dist/Memory-Usage/>

=back


=head1 SEE ALSO

=over 4

=item * L<Memchmark>

Iteratively run coderefs (similar to L<Benchmark>) and compare their memory
usage.  Useful for optimizing specific subroutines with large memory usage once
you've identified them as memory hogs.  Uses same technique for gathering usage
information as this module, so accuracy and precision suffer similarly.

=item * L<Devel::Size>

Show the size of Perl variables.  Also useful for microoptimzations when you
know what you're looking for.  Looks at Perl internals, so accuracy is good.

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Dave O'Neill.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Memory::Usage
