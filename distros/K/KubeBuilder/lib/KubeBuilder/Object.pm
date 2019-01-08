package KubeBuilder::Object;
  use Moose;
  use KubeBuilder::Property;

  has original_schema => (is => 'ro', required => 1, isa => 'Swagger::Schema::Schema');
  has resolved_schema => (is => 'ro', lazy => 1, default => sub {
    my $self = shift;
    if (defined $self->original_schema->ref) {
      return $self->root_schema->resolve_path($self->original_schema->ref)->object;
    } else {
      return $self->original_schema;
    }
  });

  has name => (is => 'ro', isa => 'Str', required => 1);

  has object_name => (is => 'ro', isa => 'Str', lazy => 1, default => sub {
    my $self = shift;
    $self->_split_name->[-1];
  });

  our $ns_mappings = {
    'io' => 'IO',
    'kube-aggregator' => 'KubeAggregator',
    'apiextensions-apiserver' => 'ApiExtensionsApiServer'
  };

  has namespace => (is => 'ro', isa => 'Str', lazy => 1, default => sub {
    my $self = shift;
    my @ns = @{ $self->_split_name };
    pop @ns;
    @ns = map { 
      my $ns = $_;
      $ns = (defined $ns_mappings->{ $ns }) ? $ns_mappings->{ $ns } : $ns;
      substr($ns, 0, 1) = uc substr($ns, 0, 1);
      $ns;
    } @ns;
    return join '::', @ns;
  });

  has _split_name => (is => 'ro', isa => 'ArrayRef[Str]', lazy => 1, default => sub {
    my $self = shift;
    my @parts = split /\./, $self->name;
    return \@parts;
  });

  has fully_namespaced => (is => 'ro', lazy => 1, isa => 'Str', default => sub {
    my $self = shift;
    return join '::', $self->namespace, $self->object_name;
  });

  has root_schema => (
    is => 'ro',
    isa => 'KubeBuilder',
    weak_ref => 1,
    required => 1,
  );

  sub get_attributes_from_properties {
    my ($self, $object) = @_;

    my $atts = { };

    my $properties = $object->properties;
    foreach my $prop_name (sort keys %$properties){
      my $prop_schema = $properties->{ $prop_name };

      my $type = $self->name . "_${prop_name}" if (defined $prop_schema->properties);

      $atts->{ $prop_name } = KubeBuilder::Property->new(
        original_schema => $prop_schema,
        root_schema => $self->root_schema,
        original_name => $prop_name,
        (defined $type) ? (type => $type) : (),
      );
    }
    if (defined $object->allOf) {
      foreach my $extra_object_properties (@{ $object->allOf }) {
        $self->root_schema->log->warn('Need to resolve allOf');
        #push @$atts, @{ $self->get_attributes_from_properties($extra_object_properties) };
      }
    }

    return $atts;
  }

  has _attributes => (
    is => 'ro',
    isa => 'HashRef[KubeBuilder::Property]',
    lazy => 1,
    default => sub {
      my $self = shift;

      return $self->get_attributes_from_properties($self->resolved_schema);
    },
    traits => [ 'Hash' ],
    handles => {
      attribute_names => 'keys',
      attribute => 'get',
    },
  );

1;
