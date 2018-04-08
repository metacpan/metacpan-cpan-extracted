package Druid::Factory::FilterFactory;
use Moo;

use Druid::Filter::Regex;
use Druid::Filter::Selector;
use Druid::Filter::Logical::And;
use Druid::Filter::Logical::Or;
use Druid::Filter::Logical::Not;

sub selector {
   my $self = shift;
   my ( $dimension, $value) = @_;

   return Druid::Filter::Selector->new(
        dimension => $dimension,
        value     => $value
    );
}

sub regex {
   my $self = shift;
   my ( $dimension, $pattern) = @_;

   return Druid::Filter::Regex->new(
        dimension => $dimension,
        pattern   => $pattern
    );
}

sub and {
    my $self = shift;
    my $fields = shift;

    return Druid::Filter::Logical::And->new(
        fields => $fields
    );
}

sub or {
    my $self = shift;
    my $fields = shift;

    return Druid::Filter::Logical::Or->new(
        fields => $fields
    );
}

sub not {
    my $self = shift;
    my $fields = shift;

    return Druid::Filter::Logical::Not->new(
        fields => $fields
    );
}

1;
