#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2020 -- leonerd@leonerd.org.uk

package Metrics::Any::Adapter::Null 0.06;

use v5.14;
use warnings;

=head1 NAME

C<Metrics::Any::Adapter::Null> - a metrics reporting adapter which does nothing

=head1 DESCRIPTION

This L<Metrics::Any> adapter type contains an empty stub implementation of the
adapter API, allowing a module to invoke methods on its metrics collector that
do not do anything.

A program would run with this adapter by default unless it has requested a
different one, via the C<use Metrics::Any::Adapter> statement.

=cut

sub new
{
   my $class = shift;
   return bless {}, $class;
}

# All of these are empty methods
foreach my $method (qw(
   make_counter      inc_counter_by
   make_distribution report_distribution
   make_gauge        inc_gauge_by  set_gauge_to
   make_timer        report_timer
)) {
   no strict 'refs';
   *$method = sub {};
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
