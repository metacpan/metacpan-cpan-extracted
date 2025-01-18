package Linux::libperf::Simple;
use strict;
use warnings;

use Exporter qw(import);

our @EXPORT_OK = qw(run report);

our $VERSION;
BEGIN {
  $VERSION = "1.001";
  use XSLoader;
  XSLoader::load("Linux::libperf::Simple" => $VERSION);
}

sub CLONE_SKIP {}

sub run {
  my ($code) = @_;

  my $perf = __PACKAGE__->new;
  $perf->enable;
  $code->();
  $perf->disable;
  my $result = $perf->results;
  undef $perf;

  return $result;
}

sub _pretty {
  my $num = shift;
  while ($num =~ s/(.*\d)(\d{3})(?:$|(?=,))/$1,$2/) {
  }
  $num;
}

sub report {
  my ($code) = @_;

  my $result = run($code);
  for my $key (sort keys %$result) {
    print "$key: ", _pretty($result->{$key}{val}), "\n";
  }
}

1;

__END__

=head1 NAME

Linux::libperf::Simple - simple wrapper around libperf

=head1 SYNOPSIS

  use Linux::libperf::Simple;

  my $p = Linux::libperf::Simple->new;
  $p->enable;
  # perform in-process task to measure
  $p->disable;
  my $result = $p->results;

=head1 DESCRIPTION

This module is a simple wrapper around Linux F<libperf>.

It is intended for use in measuring in-process execution time for
precise benchmarking, whether it will actually be useful for that
remains to be seen.

You will need to install the package (Redhat-ish) or build from source
(Debian-ish at this time).  F<libperf> is supplied as part of the
Linux source tree, it is B<not> C<theonewolf/libperf> from Github.

To build from source extract the linux sources, the more recent the
better:

  cd tools/lib/perf
  make prefix=/where/to/install install

To actually use this module you will either need to be root, or
C<kernel.perf_event_paranoid> may need to be set to a lower value than
the default, look this up before using it.

=head1 METHODS

=over

=item new()

Create a new object, no parameters (yet).

=item enable()

=item disable()

Enable or disable stats collection.

You can enable and disable multiple times.  Statistics are cumulative.

=item results()

Returns a hash reference where the keys are (intended to be) the keys
used by the C<perf> tool, and the values are each a hash ref with the
following possible keys (some are currently never used):

=over

=item * val - the value of the captured statistic

=item * enabled

=item * id

=item * lost

=item * run

=back

=back

=head1 EXPORTABLE FUNCTIONS

=over

=item run(CODEREF)

  use Linux::libperf::Simple "run";
  my $results = run(sub { code to check });

Run CODEREF and returning the timing from running it.  Returns a
hashref as per results() above.

=item report(CODEREF)

  use Linux::libperf::Simple "report";
  report(sub { code to check });

Run CODEREF and produces a simple report to standard output.

=back

=head1 TROUBLESHOOTING

Unfortunately C<libperf>'s reporting isn't very good, if libperf fails
to initialize try using F<strace> to see details on which system call
actually failed, eg you might try:

  strace -o trace.txt perl -MLinux::libperf::Simple=run -e 'run(sub {})'

and look over F<trace.txt> to see why it failed.

=head1 BUGS

Everything is subject to change.

=head1 AUTHOR

Tony Cook <tony@develop-help.com>

=cut
