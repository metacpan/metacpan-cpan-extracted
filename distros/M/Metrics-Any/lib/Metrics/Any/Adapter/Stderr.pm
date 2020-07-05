#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2020 -- leonerd@leonerd.org.uk

package Metrics::Any::Adapter::Stderr 0.06;

use v5.14;
use warnings;
use base qw( Metrics::Any::Adapter::File );

=head1 NAME

C<Metrics::Any::Adapter::Stderr> - write metrics to C<STDERR>

=head1 SYNOPSIS

   use Metrics::Any::Adapter 'Stderr';

This L<Metrics::Any> adapter type writes observations of metric values to the
standard error stream. This may be helpful while debugging or otherwise
testing code that reports metrics.

For example, by setting the C<METRICS_ANY_ADAPTER> environment variable to
configure the adapter, a metric log will be written to the terminal as a
side-effect of running a unit test:

   $ METRICS_ANY_ADAPTER=Stderr perl -Mblib t/01test.t

=cut

sub new
{
   shift->SUPER::new( fh => \*STDERR, @_ );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
