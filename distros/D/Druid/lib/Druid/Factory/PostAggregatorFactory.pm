package Druid::Factory::PostAggregatorFactory;
use Moo;

use Druid::PostAggregator::Arithmetic;
use Druid::PostAggregator::FieldAccess;


sub arithmetic {
   my $self = shift;
   my ( $name, $fn, $fields, $ordering) = @_;

   return Druid::PostAggregator::Arithmetic->new(
        name     => $name,
        fn       => $fn,
        fields   => $fields,
        ordering => $ordering
    );
}

sub fieldAccess {
   my $self = shift;
   my ( $name, $fieldName) = @_;

   return Druid::PostAggregator::FieldAccess->new(
        name      => $name,
        fieldName => $fieldName
    );
}

1;
