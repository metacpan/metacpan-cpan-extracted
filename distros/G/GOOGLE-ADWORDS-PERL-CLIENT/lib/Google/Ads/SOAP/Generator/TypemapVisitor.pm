# Copyright 2012, Google Inc. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Custom visitor for generation of typemaps based on
# SOAP::WSDL::Generator::Visitor::Typemap, with some overriden methods via
# inheritance.

package Google::Ads::SOAP::Generator::TypemapVisitor;

use base qw(SOAP::WSDL::Generator::Visitor::Typemap);

use Class::Std::Fast::Storable;

sub set_typemap_entry {
  my ($self, $value) = @_;
  my $path = join(q{/}, @{$self->get_path()});
  my $tm = $self->get_typemap();
  if ($tm->{$path} && $path =~ m/Fault\/detail\/ApiExceptionFault/) {
    return;
  }
  $tm->{$path} = $value;
}

sub visit_XSD_Element {
  my ( $self, $ident, $element ) = ( $_[0], ident $_[0], $_[1] );

  my @path = @{ $self->get_path() };
  my $path = join '/', @path;
  my $parent = $self->get_typemap()->{ $path };

  # PATCH breaking cycles
  if (scalar(@path) > 30) {
    return;
  }
  # END PATCH

  $self->SUPER::visit_XSD_Element($_[1]);
}

sub visit_XSD_ComplexType {
  my ($self, $ident, $type) = ($_[0], ident $_[0], $_[1]);

  my $variety = $type->get_variety();
  my $derivation = $type->get_derivation();
  my $content_model = $type->get_contentModel();

  return if not $variety or ($content_model eq "simpleContent");
  if (grep {$_ eq $variety} qw(all sequence choice)) {
    # Recursively going to visit child element since the type variety is
    # either all sequence choice.
    if (my $type_name = $type->get_base()) {
      my $subtype = $self->get_definitions()->first_types()->find_type(
          $type->expand($type_name));
      for (@{$subtype->get_element() || []}) {
        $_->_accept($self);
      }
    }

    for (@{$type->get_element() || []}) {
      $_->_accept($self);
    }
  }

  # PATCH - We need to also check if the complex type has derivations and
  # include type path for all the types that derived from it.
  my $last_path_elem = pop(@{$self->get_path()});
  my $def_types = $self->get_definitions()->first_types();
  my $schema = @{$def_types->get_schema()}[1];
  my @types = @{$schema->get_type()};
  my $base_type = $type->get_name();

  if (@{$self->get_path()}[0] &&
      @{$self->get_path()}[0] eq "ApiExceptionFault") {
    @{$self->get_path()}[0] = "Fault/detail/ApiExceptionFault";
  }

  if (defined $base_type) {
    my $schemas =
        @{$self->get_definitions()->get_types()}[0]->get_schema;
    SCHEMA: foreach my $my_schema (@{$schemas}) {
      next SCHEMA if ($my_schema->isa("SOAP::WSDL::XSD::Schema::Builtin"));
      my @types = @{$my_schema->get_type()};
      TYPE: foreach my $type (@types) {
        if ($type->isa("SOAP::WSDL::XSD::ComplexType")) {
          my $type_name = $type->get_name();
          my $base = $type->get_base();
          next TYPE if !$base;
          $base =~ s{ .*: }{}xms;
          if ($base eq $base_type) {
            # Checking for infinite cycles if the type has already been mapped
            # before we skip to the next one.
            foreach my $path_elem (@{$self->get_path()}) {
              next TYPE if $path_elem eq $last_path_elem . "[$type_name]";
            }

            # In this case we generate a new path that includes the type name
            # E.G. /elem1/elem2[type]
            if ($last_path_elem =~ m/\[[^\]]+\]/) {
              $last_path_elem =~ s/\[[^\]]+\]/[${type_name}]/;
              push(@{$self->get_path()}, $last_path_elem);
            } else{
              push(@{$self->get_path()}, $last_path_elem . "[$type_name]");
            }
            my $typeclass = $self->get_resolver()->create_xsd_name($type);

            # Setting current typemap class before to allow it to be used from
            # inside _accept.
            $self->set_typemap_entry($typeclass);
            $type->_accept($self);

            # Setting it afterwards again since accept could have touch it.
            $self->set_typemap_entry($typeclass);
            pop(@{$self->get_path()});
          }
        }
      }
    }
  }
  push(@{$self->get_path()}, $last_path_elem);
  # END OF PATCH.

  return if (!$derivation);

  if ($derivation eq "restriction") {
    # Resolving the base, getting atomic type and runnning on elements.
    if (my $type_name = $type->get_base()) {
      my $subtype = $self->get_definitions()->first_types()->find_type(
          $type->expand($type_name));
      for (@{$subtype->get_element() || []}) {
        $_->_accept($self);
      }
    }
  } elsif ($derivation eq "extension") {
    # Resolving the base, getting atomic type and runnning on elements.
    while (my $type_name = $type->get_base()) {
      $type = $self->get_definitions()->first_types()->find_type(
          $type->expand($type_name));
      for (@{$type->get_element() || []}) {
        $_->_accept($self);
      }
    }
  }
}

return 1;
