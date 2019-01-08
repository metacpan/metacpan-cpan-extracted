package KubeBuilder::TypeInferer;
  use Moose::Role;
  use Data::Dumper;

  requires 'root_schema';
  requires 'resolved_schema';
  requires 'type';

  has perl_type => (
    is => 'ro',
    isa => 'Str',
    lazy => 1,
    builder => '_build_perl_type',
  );

  sub _build_perl_type {
    my $self = shift;

    if (defined $self->type){
      return $self->fully_namespaced;
    }

    my $schema = $self->resolved_schema;

    if ($schema->can('type') and defined $schema->type) {
      if      ($schema->type eq 'string') {
        return 'Str';
      } elsif ($schema->type eq 'integer') {
        return 'Int';
      } elsif ($schema->type eq 'boolean') {
        return 'Bool';
      } elsif ($schema->type eq 'number') {
        return 'Num';
      } elsif ($schema->type eq 'array') {
        my $inner;
        if (not blessed($schema->items) or defined $schema->items->type) {
          my $type;
          my $items = $schema->items;
          if (not blessed($items)) {
            $type = $items->{ type };
          } elsif (defined $items->type){
            $type = $items->type;
          }
          if      ($type eq 'string'){
            $inner = 'Str';
          } elsif ($type eq 'integer'){
            $inner = 'Int';
          } else {
            $inner = 'Any';
            $self->root_schema->log->debug(Dumper({ %$self, root_schema => undef }));
            $self->root_schema->log->warn("Find out what Moose native type for $type");
          }
        } elsif (defined $self->original_schema->items->ref) {
          if ($self->original_schema->items->ref =~ m/v1beta1.JSON/) {
            $inner = 'Any';
          } else {
            my $object = $self->root_schema->object_for_ref($schema->items);
            $inner = $object->fully_namespaced;
          }
        }
        return "ArrayRef[$inner]";
      } elsif ($schema->can('type') and $schema->type eq 'object') {
        if (defined $schema->additionalProperties) {
          # the existence of additionalProperties indicates that it's a "map" object (a HashRef in Perl terms) whose keys are strings, and values of a type described in additionalProperties
          my $props = $schema->additionalProperties;
          if (defined $props->ref) {
            $props = $self->root_schema->resolve_path($props->ref)->object;
          }
          if (defined $props->type) {
            return 'HashRef[Str]' if ($props->type eq 'string');
            return 'HashRef[Num]' if ($props->type eq 'number');
            return 'HashRef[HashRef]' if ($props->type eq 'object');
            if ($props->type eq 'array') {
              my $items = $props->items;
              return 'HashRef[ArrayRef[Str]]' if ($items->type eq 'string');
              return 'HashRef[ArrayRef[ArrayRef[HashRef]]]' if ($items->type eq 'array' and $items->items->type eq 'object');
            }
          } elsif (defined $props->ref) {
            return "HashRef" if ($props->ref eq '#/definitions/io.k8s.apiextensions-apiserver.pkg.apis.apiextensions.v1beta1.JSONSchemaProps');
            die "Unknown HashRef type " . Dumper({ %$self, root_schema => undef }, "$self");
          }
        } elsif (defined $schema->properties) {
          # If it has properties in it's schema element, it has to have a proper name
          $self->fully_namespaced;
        } else {
          return 'HashRef';
        }
      } else {
        $self->root_schema->log->debug(Dumper({ %$self, root_schema => undef }));
        $self->root_schema->log->warn('I Can\'t find a Perl type because self->type and self->schema is undefined on ' . ref($self) );
        return 'Any'
      }
    } elsif ($schema->can('schema') and defined $schema->schema) {
      if (defined $schema->schema->ref) {
        my $obj = $self->root_schema->object_for_ref($schema->schema);
        return $obj->fully_namespaced;
      } elsif (defined $schema->schema->type) {
        my $type = $schema->schema->type;
        my $inner;

        if      ($type eq 'string'){
          $inner = 'Str';
        } elsif ($type eq 'integer'){
          $inner = 'Int';
        } else {
          $inner = 'Any';
          $self->root_schema->log->debug(Dumper({ %$self, root_schema => undef }, "$self"));
          $self->root_schema->log->warn("Find out what Moose type for $type");
        }
        return $inner;
      }
    } elsif ($self->isa('KubeBuilder::Object')) {
      return $self->fully_namespaced;
    } elsif ($self->isa('KubeBuilder::Property')) {
      # if the resolved schema has no properties...
      # it's a hackish way of knowing that the object has no attributes assigned to it
      return 'Any' if (keys %{ $self->resolved_schema } == 0);
      return 'Any' if ($self->original_schema->ref =~ m/v1beta1.JSON/);
      return $self->object_definition->fully_namespaced;
    } else {
      $self->root_schema->log->debug(Dumper({ %$self, root_schema => undef }));
      $self->root_schema->log->debug($self);
      $self->root_schema->log->warn('II Can\'t find a Perl type because self->type and self->schema is undefined on ' . ref($self) );
      return 'Any'
    }
  }

1;
