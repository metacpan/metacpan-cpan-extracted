package KubeBuilder::Property;
  use Moose;

  # Have to declare these three so that the TypeInferer knows that this class will implement them
  sub root_schema;
  sub resolved_schema;
  sub type;
  with 'KubeBuilder::TypeInferer';

  has original_schema => (is => 'ro', required => 1, isa => 'Swagger::Schema::Schema');
  has resolved_schema => (is => 'ro', lazy => 1, default => sub {
    my $self = shift;
    if (defined $self->original_schema->ref) {
      return $self->root_schema->resolve_path($self->original_schema->ref)->object;
    } else {
      return $self->original_schema;
    }
  });
  has object_definition => (is => 'ro', lazy => 1, default => sub {
    my $self = shift;
    return $self->root_schema->object_for_ref($self->original_schema);
  });
  # passed in the constructor if the caller knows what type this object is
  # this happens for inlined objects with no names (the caller has to make
  # up the name)
  has type => (is => 'ro', isa => 'Str');

  has root_schema => (
    is => 'ro',
    isa => 'KubeBuilder',
    weak_ref => 1,
    required => 1,
  );


1;
