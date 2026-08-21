package Math::Histo::CLI;

use strict;
use warnings;
use Math::Histo ();

our $VERSION = '0.1.0';

# Handled by XS: Math::Histo::CLI::run and Math::Histo::CLI::run_raw

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Math::Histo::CLI - In-Process CLI Toolkit Execution for Math::Histo

=head1 SYNOPSIS

  use Math::Histo::CLI;

  # Execute the multi-call CLI dispatcher in-process
  my $status = Math::Histo::CLI->run('plot', 'data.histo', '--style=shaded');

  # Pipe/fill data directly
  my $status = Math::Histo::CLI->run('fill', '--bins=50', '--min=0', '--max=100', 'samples.txt');

=head1 DESCRIPTION

C<Math::Histo::CLI> exposes the modular C99 CLI and terminal visualization toolkit
(C<libhistocli>) directly to Perl in-process without spawning subprocesses or requiring
external executable binary lookups.

Available Subcommands:
  - C<fill>: Stream data in, aggregate into 1D/2D histogram, and emit serialized output.
  - C<plot>: Render histogram as ASCII, Unicode blocks, shaded bars, or sparklines.
  - C<stats>: Display comprehensive statistical summary, moments, and quantiles.
  - C<fit>: Fit parametric models (Gaussian, Exponential, Polynomial, Breit-Wigner).
  - C<cmp>: Compare two histograms and compute statistical distance metrics.

=head1 METHODS

=over 4

=item B<run(@args)>

Executes the CLI dispatcher with the given command-line argument list. Returns integer exit status code (0 for success).

=item B<run_raw(@argv)>

Executes the CLI dispatcher where C<$argv[0]> is the program invocation name.

=back

=head1 SEE ALSO

=over 4

=item * L<Math::Histo>

=item * L<Alien::libhisto>

=back

=head1 AUTHOR

Steffen Mueller E<lt>cpan@steffen-mueller.netE<gt>

=head1 LICENSE

MIT License. Copyright (c) 2026 Steffen Mueller and libhisto contributors.

=cut
