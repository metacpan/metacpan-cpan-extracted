package Memory::Process;

use base qw(Memory::Usage);
use strict;
use warnings;

use Readonly;

# Constants.
Readonly::Scalar our $EMPTY_STR => q{};

our $VERSION = 0.06;

# Record.
sub record {
	my ($self, $message, $pid) = @_;
	if (! defined $message) {
		$message = $EMPTY_STR;
	}
	return $self->SUPER::record($message, $pid);
}

# Print report to STDERR.
sub dump {
	my $self = shift;
	return print STDERR scalar $self->report;
}

# Get report.
sub report {
	my $self = shift;
	my $report = $self->SUPER::report;
	my @report_full = split m/\n/ms, $report;
	my @report = ();
	if (@report_full > 2) {
		@report = ($report_full[0], $report_full[-2], $report_full[-1]);
	};
	my $report_scalar = (join "\n", @report);
	if ($report_scalar ne $EMPTY_STR) {
		$report_scalar .= "\n";
	}
	return wantarray ? @report : $report_scalar;
}

# Reset records.
sub reset {
	my $self = shift;
	@{$self} = ();
	return;
}

# Get state.
sub state {
	my $self = shift;
	return [@{$self}];
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

 Memory::Process - Perl class to determine actual memory usage.

=head1 SYNOPSIS

 use Memory::Process;

 my $m = Memory::Process->new(%params);
 $m->dump;
 $m->record($message, $pid);
 my @report = $m->report;
 my $report = $m->report;
 $m->reset;
 $m->state;

=head1 METHODS

=head2 C<new>

 my $m = Memory::Process->new(%params);

Constructor.

Returns instance of object.

=head2 C<dump>

 $m->dump;

Print report to STDERR.

Returns return value of print().

=head2 C<record>

 $m->record($message, $pid);

Set record.
If message not set, use ''.

Returns undef.

=head2 C<report>

 my @report = $m->report;
 my $report = $m->report;

Get report.

In scalar context returns string with report.
In array context returns array of report lines.
First line is title.

=head2 C<reset>

 $m->reset;

Reset records.

Returns undef.

=head2 C<state>

 $m->state;

Get internal state.

Each state item consists from:

 - timestamp (in seconds since epoch)
 - message (from record())
 - virtual memory size (in kB)
 - resident set size (in kB)
 - shared memory size (in kB)
 - text size (in kB)
 - data and stack size (in kB)

Returns reference to array with state items.

=head1 EXAMPLE1

=for comment filename=run_process_and_get_report.pl

 use strict;
 use warnings;

 use Memory::Process;

 # Object.
 my $m = Memory::Process->new;

 # Example process.
 $m->record("Before my big method");
 my $var = ('foo' x 100);
 sleep 1;
 $m->record("After my big method");
 sleep 1;
 $m->record("End");

 # Print report.
 print $m->report."\n";

 # Output like:
 #   time    vsz (  diff)    rss (  diff) shared (  diff)   code (  diff)   data (  diff)
 #      1  19120 (     0)   2464 (     0)   1824 (     0)      8 (     0)   1056 (     0) After my big method
 #      2  19120 (     0)   2464 (     0)   1824 (     0)      8 (     0)   1056 (     0) End

=head1 EXAMPLE2

=for comment filename=run_process_and_get_state.pl

 use strict;
 use warnings;

 use Data::Printer;
 use Memory::Process;

 # Object.
 my $m = Memory::Process->new;

 # Example process.
 $m->record("Before my big method");
 my $var = ('foo' x 100);
 sleep 1;
 $m->record("After my big method");
 sleep 1;
 $m->record("End");

 # Print report.
 my $state_ar = $m->state;

 # Dump out.
 p $state_ar;

 # Output like:
 # \ [
 #     [0] [
 #         [0] 1445941214,
 #         [1] "Before my big method",
 #         [2] 33712,
 #         [3] 7956,
 #         [4] 3876,
 #         [5] 8,
 #         [6] 4564
 #     ],
 #     [1] [
 #         [0] 1445941215,
 #         [1] "After my big method",
 #         [2] 33712,
 #         [3] 7956,
 #         [4] 3876,
 #         [5] 8,
 #         [6] 4564
 #     ],
 #     [2] [
 #         [0] 1445941216,
 #         [1] "End",
 #         [2] 33712,
 #         [3] 7956,
 #         [4] 3876,
 #         [5] 8,
 #         [6] 4564
 #     ]
 # ]

=head1 DEPENDENCIES

L<Memory::Usage>,
L<Readonly>.

=head1 SEE ALSO

=over

=item L<Memory::Stats>

Memory Usage Consumption of your process

=item L<Memory::Usage>

Tools to determine actual memory usage

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Memory-Process>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz/>

=head1 LICENSE AND COPYRIGHT

© 2014-2023 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.06

=cut
