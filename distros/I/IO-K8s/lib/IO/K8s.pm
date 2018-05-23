package IO::K8s;
  use Moose;

  our $VERSION = '0.03';

  use Moose::Util qw/find_meta/;
  use Module::Runtime qw/require_module/;
  use JSON::MaybeXS;

  has json => (is => 'ro', default => sub {
    return JSON::MaybeXS->new->canonical;
  });

  sub load_class {
    my $class = shift;
    require_module $class;
  }

  sub json_to_object {
    my ($self, $class, $json) = @_;
    my $struct = $self->json->decode($json);
    return $self->struct_to_object($class, $struct);
  }

  sub struct_to_object {
    my ($self, $class, $params) = @_;

    load_class($class);

    my %args;

    my $class_meta = find_meta $class;

    foreach my $class_att ($class_meta->get_all_attributes) {
      my $att_name = $class_att->name;

      next if (not defined $params->{ $att_name });

      if ($class_att->type_constraint->is_a_type_of('ArrayRef')) {
        my $inner_type = $class_att->type_constraint->type_parameter;
        if ($inner_type->is_a_type_of('Object')){
          $args{ $att_name } = [ map { $self->struct_to_object($inner_type->name, $_) } @{ $params->{ $att_name } } ];
        } else {
          $args{ $att_name } = $params->{ $att_name };
        }
      } elsif ($class_att->type_constraint->is_a_type_of('HashRef')) {
        if ($class_att->type_constraint->isa('Moose::Meta::TypeConstraint::Parameterizable')) {
          # Only a HashRef type...
          $args{ $att_name } = $params->{ $att_name } 
        } else {
          # HashRef[...] type
          my $inner_type = $class_att->type_constraint->type_parameter;
          if ($inner_type->is_a_type_of('Object')){
            $args{ $att_name } = { map { ($_ => $self->struct_to_object($inner_type->name, $params->{ $att_name }->{ $_ })) } keys %{ $params->{ $att_name } } };
          } else {
            $args{ $att_name } = $params->{ $att_name };
          }
        }
      } elsif ($class_att->type_constraint->is_a_type_of('Object')){
        $args{ $att_name } = $self->struct_to_object($class_att->type_constraint->class, $params->{ $att_name });
      } elsif ($class_att->type_constraint->is_a_type_of('Bool')) {
        if (lc($params->{ $att_name }) eq 'true' or $params->{ $att_name } == 1) {
          $args{ $att_name } = 1;
        } else {
          $args{ $att_name } = 0;
        }
      } else {
        $args{ $att_name } = $params->{ $att_name };
      }
    }

    return $class->new(%args);
  }

  sub _is_internal_type {
    my ($self, $att_type) = @_;
    return ($att_type eq 'Str' or $att_type eq 'Int' or $att_type eq 'Bool' or $att_type eq 'Num');
  }

  sub object_to_struct {
    my ($self, $object) = @_;
    my $struct = {};

    foreach my $attribute ($object->meta->get_all_attributes) {
      my $att = $attribute->name;
      next if (not defined $object->$att);

      my $key = $att;
      my $att_type = $attribute->type_constraint;

      if ($att_type eq 'Bool') {
        $struct->{ $key } = ($object->$att) ? JSON->true : JSON->false;
      } elsif ($att_type eq 'Int') {
        $struct->{ $key } = int($object->$att);
      } elsif ($self->_is_internal_type($att_type)) {
        $struct->{ $key } = $object->$att;
      } elsif ($att_type =~ m/^ArrayRef\[(.*)\]/) {
        my $internal_type = "$1";
        if ($self->_is_internal_type($internal_type)){
          $struct->{ $key } = $object->$att;
        } else { 
          $struct->{ $key } = [ map { $self->object_to_struct($_) } @{ $object->$att } ];
        }
      } elsif ($att_type =~ m/^HashRef\[(.*)\]/) {
        my $internal_type = "$1";
        if ($self->_is_internal_type($internal_type)){
          $struct->{ $key } = $object->$att;
        } else {
          # HashRef of objects
          $struct->{ $key } = { map { ($_ => $self->object_to_struct($object->$att->{$_})) } keys %{ $object->$att } };
        }
      } else {
        $struct->{ $key } = $self->object_to_struct($object->$att);
      }
    }

    return $struct;
  }

  sub object_to_json {
    my ($self, $object) = @_;
    return $self->json->encode($self->object_to_struct($object));
  }

1;

### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

IO::K8s - Objects representing things found in the Kubernetes API

=head1 SYNOPSIS

  use IO::K8s
  
  my $k8s = IO::K8s->new;

  my $object = $k8s->json_to_object('IO::K8s::Api::Core::V1::Service', '{"kind":"Service"}');
  # $object is an IO::K8s::Api::Core::V1::Service object
  my $json = $k8s->object_to_json($object);
  # $json is JSON that we can send to the Kubernetes API

  my $object = $k8s->struct_to_object('IO::K8s::Api::Core::V1::Service', { kind => 'Service' });
  # $object is an IO::K8s::Api::Core::V1::Service object
  my $struct = $k8s->object_to_struct($object);
  # $struct is a hashref that can be transformed to JSON

=head1 DESCRIPTION

This module is the set of objects and serialization / deserialization methods that represent
the structures found inside the Kubernetes API L<https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.10/>

Kubernetes API is very strict about the input it accepts. When a value is expected to be an integer, 
if it's sent as a string with a number inside, it won't get accepted by the API. This module helps you
get the correct value types in the JSON that can later be sent to Kubernetes.

Another use case is inflating the JSON returned by Kubernetes into objects.

=head1 SEE ALSO

L<https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.10/>

=head1 AUTHOR

    Jose Luis Martinez
    CAPSiDE
    jlmartinez@capside.com

=head1 BUGS and SOURCE

The source code is located here: L<https://github.com/pplu/io-k8s-p5>

Please report bugs to: L<https://github.com/pplu/io-k8s-p5/issues>

=head1 COPYRIGHT and LICENSE

Copyright (c) 2018 by CAPSiDE

This code is distributed under the Apache 2 License. The full text of the 
license can be found in the LICENSE file included with this module.

=cut
