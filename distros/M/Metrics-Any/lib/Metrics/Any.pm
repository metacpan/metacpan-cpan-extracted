#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2020 -- leonerd@leonerd.org.uk

package Metrics::Any 0.06;

use v5.14;
use warnings;

use Metrics::Any::Collector;

=head1 NAME

C<Metrics::Any> - abstract collection of monitoring metrics

=head1 SYNOPSIS

In a module:

   use Metrics::Any '$metrics',
      strict => 0,
      name_prefix => [ 'my_module_name' ];

   sub do_thing {
      $metrics->inc_counter( 'things_done' );
   }

In a program or top-level program-like module:

   use Metrics::Any::Adapter 'Prometheus';

=head1 DESCRIPTION

Provides a central location for modules to report monitoring metrics, such as
counters of the number of times interesting events have happened, and programs
to collect up and send those metrics to monitoring services.

Inspired by L<Log::Any>, this module splits the overall problem into two
sides. Modules wishing to provide metrics for monitoring purposes can use the
C<use Metrics::Any> statement to obtain a I<collector> into which they can
report metric events. By default this collector doesn't actually do anything,
so modules can easily use it without adding extra specific dependencies for
specific reporting.

A program using one or more such modules can apply a different policy and
request a particular I<adapter> implementation in order to actually report
these metrics to some external system, by using the
C<use Metrics::Any::Adapter> statement.

This separation of concerns allows module authors to write code which will
report metrics without needing to care about the exact mechanism of that
reporting (as well as to write code which does not itself depend on the code
required to perform that reporting).

=head2 Future Direction

At present this interface is in an early state of experimentation. The API
is fairly specifically-shaped for L<Net::Prometheus> at present, but it is
hoped with more adapter implementations (such as for statsd or OpenTelemetry)
the API shapes can be expanded and made more generic to support a wider
variety of reporting mechanisms.

As a result, any API details for now should be considered experimental and
subject to change in later versions.

=cut

=head1 USE STATEMENT

For a module to use this facility, the C<use> statement importing it should
give the name of a variable (as a plain string) to store the collector for
that package.

   use Metrics::Any '$metrics';

This variable will be created in the calling package and populated with an
instance of L<Metrics::Any::Collector>. The module can then use the collector
API to declare new metrics, and eventually report values into them.

Note that the variable is created at the package level; any other packages
within the same file will not see it and will have to declare their own.

=cut

sub import
{
   my $pkg = shift;
   my $caller = caller;
   $pkg->import_into( $caller, @_ );
}

my %collector_for_package;

sub import_into
{
   my ( $pkg, $caller, @args ) = @_;

   my $varname = $1 and shift @args if @args and $args[0] =~ m/^\$(.*)$/;

   my $collector = $collector_for_package{$caller} //= Metrics::Any::Collector->new( $caller, @args );

   if( defined $varname ) {
      no strict 'refs';
      *{"${caller}::${varname}"} = \$collector;
   }
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
