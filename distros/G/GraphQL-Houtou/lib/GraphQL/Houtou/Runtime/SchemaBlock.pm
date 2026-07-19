package GraphQL::Houtou::Runtime::SchemaBlock;

use 5.014;
use strict;
use warnings;

sub new {
  my ($class, %args) = @_;
  return bless {
    name => $args{name},
    family => $args{family} || 'ROOT',
    root_type_name => $args{root_type_name},
    slots => $args{slots} || [],
  }, $class;
}

sub name { return $_[0]{name} }
sub family { return $_[0]{family} }
sub root_type_name { return $_[0]{root_type_name} }
sub slots { return $_[0]{slots} }

sub to_struct {
  my ($self) = @_;
  return {
    name => $self->{name},
    family => $self->{family},
    root_type_name => $self->{root_type_name},
    slots => [ map { $_->to_struct } @{ $self->{slots} || [] } ],
  };
}

1;
