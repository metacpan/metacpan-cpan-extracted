#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2020 -- leonerd@leonerd.org.uk

package Metrics::Any::Adapter::Routable 0.01;

use v5.24;  # postfix deref
use warnings;
use experimental 'signatures';

use Carp;
use List::Util 1.39 qw( any pairs );

require Metrics::Any::Adapter; Metrics::Any::Adapter->VERSION( '0.06' );

=head1 NAME

C<Metrics::Any::Adapter::Routable> - configurable routing of reported metrics

=head1 SYNOPSIS

   use Metrics::Any::Adapter 'Routable',
      targets => [
         [ "important", "Statsd" ],
         [ "default",   "Prometheus" ],
         [ ["default", "debug"], "File", path => "metrics.log" ],
      ],
      packages => {
         "My::Application" => "important",
         "Net::Async::HTTP" => "debug",
         "IO::Async::*" => "debug", # wildcard matches
         # anything else will be assigned "default"
      };

=head1 DESCRIPTION

This L<Metrics::Any> adapter type acts as a proxy for a set of multiple other
adapters, allowing an application to configure which adapter (or adapters) to
send particular metrics into.

Routing of metrics is done by a "category" name. Each reported metric is
assigned into a category, which is a string. Each configured adapter declares
an interest in one or more category names. Reported metrics are then routed
only to those adapters which declared an interest in the category.

Primarily the category names are set by the C<packages> configuration
argument. Additionally, this can be overridden by any individual metric when
it is constructed by providing a C<category> parameter to the C<make_*> method
which created it.

=head1 ARGUMENTS

The following additional arguments are recognised

=head2 targets

   targets => [
      [ $category, $type, ],
      [ $category, $type, @args ],
      [ [ @categories ], $type, @args ],
      ...
   ],

A reference to an array containing a list of targets. Each target consists of
a category name (or reference array containing a list of categories), a type
name, and an optional set of constructor arguments, all stored in its own
array reference.

These targets will all be constructed and stored by the adapter.

=head2 packages

   packages => {
      $package => $category,
      ...
   }

A reference to a hash associating a category name with a reporting package.
Any metrics registered by the given package will be associated with the given
category name.

A pattern can also be specified with a trailing C<::*> wildcard; this will
match any package name within the given namespace. Longer matches will take
precedence over shorter ones.

Any reported metric that does not otherwise have a category configured will be
assigned the category C<default>.

=cut

sub new ( $class, %args )
{
   my $self = bless {
      package_category => {},
      metric_category => {},
      targets => [],
   }, $class;

   $self->add_target( @$_ ) for $args{targets}->@*;

   $self->set_category_for_package( $_->key, $_->value ) for pairs $args{packages}->%*;

   return $self;
}

sub add_target ( $self, $categories, $type, @args )
{
   ref $categories eq "ARRAY" or $categories = [ $categories ];

   my $adapter = Metrics::Any::Adapter->class_for_type( $type )->new( @args );

   push $self->{targets}->@*, [ $categories, $adapter ];
}

sub category_for_package ( $self, $package )
{
   my $categories = $self->{package_category};

   return $categories->{$package} if exists $categories->{$package};

   while( length $package ) {
      return $categories->{"${package}::*"} if exists $categories->{"${package}::*"};
      $package =~ s/::[^:]+$// or last;
   }
   return undef;
}

sub set_category_for_package ( $self, $package, $category )
{
   $self->{package_category}{$package} = $category;
}

foreach my $method (qw( make_counter make_distribution make_gauge make_timer )) {
   my $code = sub ( $self, $handle, %args ) {
      my $collector = $args{collector};

      $self->{metric_category}{$handle} = $args{category} //
         $self->category_for_package( $collector->package ) //
         # TODO: a configurable default category
         "default";

      my @e;
      foreach my $target ( $self->{targets}->@* ) {
         my ( undef, $adapter ) = @$target;

         defined eval { $adapter->$method( $handle, %args ); 1 } or
            push @e, $@;
      }
      die $e[0] if @e;
   };

   no strict 'refs';
   *$method = $code;
}

foreach my $method (qw( inc_counter_by report_distribution inc_gauge_by set_gauge report_timer )) {
   my $code = sub ( $self, $handle, @args ) {
      my $category = $self->{metric_category}{$handle} or
         croak "Unsure category for $handle";

      my @e;
      foreach my $target ( $self->{targets}->@* ) {
         my ( $categories, $adapter ) = @$target;

         next unless any { $_ eq $category } @$categories;

         defined eval { $adapter->$method( $handle, @args ); 1 } or
            push @e, $@;
      }
      die $e[0] if @e;
   };

   no strict 'refs';
   *$method = $code;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
