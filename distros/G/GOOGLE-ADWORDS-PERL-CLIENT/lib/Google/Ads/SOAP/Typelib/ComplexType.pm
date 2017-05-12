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
# Custom complex type object with patched logic to properly:
#  - Serialize/Deserialize objects with xsi:type
#  - Properly include namespaces when attributes are inherited from different
#    namespaces.
#  - Include built-in XPath search capabilities.
#  - Add the ability to transform from and to hashes.
# This module is based on SOAP::WSDL::XSD::Typelib::ComplexType, with some
# overriden methods via inheritance.

package Google::Ads::SOAP::Typelib::ComplexType;

use base qw(SOAP::WSDL::XSD::Typelib::ComplexType);

no warnings qw(redefine);
no strict qw(refs);
use version;

# Loading patched packages first.
use Google::Ads::Common::XPathSAXParser;

use Carp;
use Data::Dumper;
use Scalar::Util qw(blessed);
use SOAP::WSDL::Expat::Base;
use SOAP::WSDL::Expat::MessageParser;
use SOAP::WSDL::XSD::Typelib::ComplexType;

# Silencing annoying third-party library warnings.
$SIG{__WARN__}= sub {
  warn @_ unless
    $_[0] =~ /Tie::Hash::FIELDS|Cache::RemovalStrategy|XPath\/
        Node\/Element|XMLSchemaSOAP1_2::as_dateTime/;
};

# Patching of the WSDL library to include xsi:type attribute for
# elements that inherit other complex elements like ManualCPC.
sub serialize_attr {
  my ($self, $args) = @_;
  my $result = q{};
  if ($xml_attr_of{${$_[0]}}) {
    $result = $xml_attr_of{${$_[0]}}->serialize();
  }

  # PATCH to include xsi:type when necessary.
  if ($args->{xsitype}) {
    $result = $result . " xsi:type=\"$args->{xsitype}\" ";
  }
  # END OF PATCH

  if ($args->{xsitypens}) {
    $result = $result . " xmlns:$args->{xsitypens}->{name}=\"" .
        "$args->{xsitypens}->{value}\" ";
  }

  return $result;
}


# Redefining complex type factory method to allow subclasses to be passed to
# attribute setters, so for example a
# set_operations(\@{ARRAY_OF_SUBCLASSES_OF_OPERATION}) can be performed.
sub _factory {
  my $class = shift;

  $ELEMENTS_FROM->{$class} = shift;
  $ATTRIBUTES_OF->{$class} = shift;
  $CLASSES_OF->{$class} = shift;
  $NAMES_OF->{$class} = shift;

  while (my ($name, $attribute_ref) = each %{$ATTRIBUTES_OF->{$class}}) {
    my $type = $CLASSES_OF->{$class}->{$name} or
        croak "No class given for $name";
    $type->isa('UNIVERSAL') or eval "require $type" or croak $@;
    my $is_list = $type->isa('SOAP::WSDL::XSD::Typelib::Builtin::list');
    my $method_name = $name;
    $method_name =~s{[\.\-]}{_}xmsg;
    *{"$class\::set_$method_name"} = sub {
      if (not $#_) {
        delete $attribute_ref->{${$_[0]}};
        return;
      };
      my $is_ref = ref $_[1];
      $attribute_ref->{${$_[0]}} = ($is_ref)?
          ($is_ref eq 'ARRAY')?
              $is_list?
                  $type->new({value => $_[1]}):
                  [map {
                         ref $_?
                             ref $_ eq 'HASH'?
                                 # PATCH Call custom hash to object subroutine
                                 # that correctly handles xsi_type.
                                 _hash_to_object($type, $_):
                                 # An isa type comparison is needed to check
                                 # for the right type.
                                 $_->isa($type)?
                                 # END OF PATCH
                                     $_ : croak "cannot use " . ref($_) .
                                              " reference as value for" .
                                              " $name - $type required"
                             : $type->new({value => $_})
                       } @{$_[1]}]:
              $is_ref eq 'HASH'?
                  # PATCH Call custom hash to object subroutine that correctly
                  # handles xsi_type.
                  do {
                    _hash_to_object($type, $_[1]);
                  }:
                  # END OF PATCH
                  blessed $_[1] && $_[1]->isa($type)?
                      $_[1]:
                      die croak "cannot use $is_ref reference as value for " .
                                "$name - $type required":
          defined $_[1] ? $type->new({value => $_[1]}) : ();
      return;
    };

    *{"$class\::add_$method_name"} = sub {
      warn "attempting to add empty value to " . ref $_[0]
          if not defined $_[1];

      if (not exists $attribute_ref->{${$_[0]}}) {
        $attribute_ref->{${$_[0]}} = $_[1];
        return;
      }

      if (not ref $attribute_ref->{${$_[0]}} eq 'ARRAY') {
        $attribute_ref->{${$_[0]}} = [$attribute_ref->{${$_[0]}}, $_[1]];
        return;
      }

      push @{$attribute_ref->{${$_[0]}}}, $_[1];
      return;
    };
  }

  *{"$class\::new"} = sub {
    my $self = bless \(my $o = Class::Std::Fast::ID()), $_[0];

    if (exists $_[1]->{xmlattr}) {
      $self->attr(delete $_[1]->{xmlattr});
    }

    # Iterate over keys of arguments and call set appropriate field in class
    map {($ATTRIBUTES_OF->{$class}->{$_})?
        do {
          my $method = "set_$_";
          $method =~s{[\.\-]}{_}xmsg;
          $self->$method($_[1]->{$_});
        }:
        # PATCH Ignoring xsi_type as a regular attribute of a given HASH since
        # is treated specially later.
        $_ =~ m{ \A
                  xmlns|xsi_type
               }xms?():
              do {
                croak "Unknown field $_ in $class.\nValid fields are:\n" .
                      join(', ', @{$ELEMENTS_FROM->{$class}}) . "\n" .
                      "Structure given:\n" . Dumper ($_[1])
              };
        # END PATCH
    } keys %{$_[1]};
    return $self;
  };

  *{"$class\::_serialize"} = sub {
    my $ident = ${$_[0]};
    my $option_ref = $_[1];

    return \join q{} , map {
      my $element = $ATTRIBUTES_OF->{$class}->{$_}->{$ident};

      if (defined $element) {
        $element = [$element] if not ref $element eq 'ARRAY';
        my $name = $NAMES_OF->{$class}->{$_} || $_;
        my $target_namespace = $_[0]->get_xmlns();
        map {
          if ($_->isa('SOAP::WSDL::XSD::Typelib::Element')) {
            ($target_namespace ne $_->get_xmlns())?
                $_->serialize({name => $name, qualified => 1}):
                $_->serialize({name => $name});
          } else {
            if (!defined $ELEMENT_FORM_QUALIFIED_OF->{$class} or
                $ELEMENT_FORM_QUALIFIED_OF->{$class}) {
              if (exists $option_ref->{xmlns_stack} &&
                  (scalar @{$option_ref->{xmlns_stack}} >= 2) &&
                  ($option_ref->{xmlns_stack}->[-1] ne
                      $option_ref->{xmlns_stack}->[-2])) {
                join q{}, $_->start_tag({
                            name => $name,
                            xmlns => $option_ref->{xmlns_stack}->[-1],
                            %{$option_ref}
                          }),
                     $_->serialize($option_ref),
                     $_->end_tag({name => $name , %{$option_ref}});
              } else {
                # PATCH Determine if xsi:type is required.
                my $refname = ref($_);
                my $classname = $CLASSES_OF->{$class}->{$name};
                if ($classname && $classname ne ref($_)) {
                  my $xsitypens = {};
                  if ($option_ref->{xmlns_stack}->[-1] ne $_->get_xmlns()){
                    $xsitypens->{name} = "xns";
                    $xsitypens->{value} = $_->get_xmlns();
                    $option_ref->{xsitypens} = $xsitypens;
                  }
                  my $package_name = ref($_);
                  $package_name =~ /^.*::(.*)$/;
                  my $xsi_type = $1;
                  $option_ref->{xsitype} =
                      ($xsitypens->{name}?$xsitypens->{name} . ":" : "") .
                      "$xsi_type";
                } else {
                  delete $option_ref->{xsitype};
                }

                # Checks to see if namespace is required because it is an
                # inherited attribute on a different namespace.
                my $class_isa = $class . "::ISA";
                my @class_parents = @$class_isa;
                my $requires_namespace = 0;
                foreach my $parent (@class_parents) {
                  my %parent_elements =
                      map { $_ => 1 } @{$ELEMENTS_FROM->{$parent}};
                  my $parent_has_element = exists($parent_elements{$name});

                  if ($parent_has_element) {
                    my $parent_xns;
                    eval "\$parent_xns = " . $parent. "::get_xmlns()";
                    if ($parent_xns ne $option_ref->{xmlns_stack}->[-1]) {
                      $requires_namespace = 1;
                    }
                  }
                }

                if ($requires_namespace) {
                  join q{}, $_->start_tag({name => $name,
                                           xmlns => $_->get_xmlns(),
                                           %{$option_ref}}),
                       $_->serialize($option_ref),
                       $_->end_tag({name => $name , %{$option_ref}});
                } else {
                  join q{}, $_->start_tag({name => $name, %{$option_ref}}),
                       $_->serialize($option_ref),
                       $_->end_tag({name => $name , %{$option_ref}});
                }
                # END PATCH
              }
            } else {
              my $set_xmlns = delete $option_ref->{xmlns};

              join q{},
                   $_->start_tag({
                     name => $name,
                     %{$option_ref},
                     (!defined $set_xmlns)?(xmlns => ""):()
                   }),
                   $_->serialize({%{$option_ref}, xmlns => ""}),
                   $_->end_tag({name => $name , %{$option_ref}});
            }
          }
        } @{$element}
      } else {
        q{};
      }
    } (@{$ELEMENTS_FROM->{$class}});
  };

  if (!$class->isa('SOAP::WSDL::XSD::Typelib::AttributeSet')) {
    *{"$class\::serialize"} =
        \&SOAP::WSDL::XSD::Typelib::ComplexType::__serialize_complex;
  };
}

# Added to support hash to object serialization.
# A special xsi_type attribute name has been reserved to specify subtype of
# the object been passed when using hashes.
# PATCH This entire method was added to the class.
sub _hash_to_object {
  my ($type, $hash) = @_;

  if ($hash->{"xsi_type"}) {
    my $base_type = $type;
    my $xsi_type = $hash->{"xsi_type"};
    $type = substr($type, 0, rindex($type, "::") + 2) . $xsi_type;
    eval("require $type");
    die croak "xsi_type $xsi_type not found" if $@;
    my $instance = $type->new($hash);
    die croak "xsi_type $xsi_type must inherit from " . "$type"
        if not $instance->isa($base_type);
    return $instance;
  } else {
    return $type->new($hash);
  }
}
# END PATCH

# Redefining as_hash_ref method to correctly map all object properties to a
# hash structure.
sub as_hash_ref {
  my $self = $_[0];
  my $attributes_ref = $self->__get_object_attributes($self);

  my $hash_of_ref = {};
  if ($_[0]->isa('SOAP::WSDL::XSD::Typelib::Builtin::anySimpleType')) {
    $hash_of_ref->{value} = $_[0]->get_value();
  } else {
    foreach my $attribute (keys %{$attributes_ref}) {
      next if not defined $attributes_ref->{$attribute}->{${$_[0]}};
      my $value = $attributes_ref->{$attribute}->{${$_[0]}};
      # PATCH normalizing the attribute name
      $attribute =~ s/__/./g;
      # END PATCH
      $hash_of_ref->{$attribute} = blessed $value
          ? $value->isa('SOAP::WSDL::XSD::Typelib::Builtin::anySimpleType')
              ? $value->get_value()
              # PATCH returning the value no need to recurse
              : $value
              # END PATCH
          : ref $value eq 'ARRAY'
              ? [map {
                  $_->isa('SOAP::WSDL::XSD::Typelib::Builtin::anySimpleType')
                      ? $_->get_value()
                      # PATCH returning the object no need to recurse
                      : $_
                      # END PATCH
                } @{$value}]
              : die "Neither blessed obj nor list ref";
    };
  }

  no warnings "once";
  return $hash_of_ref if $_[1] or $AS_HASH_REF_WITHOUT_ATTRIBUTES;

  if (exists $xml_attr_of{${$_[0]}}) {
    $hash_of_ref->{xmlattr} = $xml_attr_of{${$_[0]}}->as_hash_ref();
  }

  return $hash_of_ref;
}

# PATCH To retrieve object attributes mapping including inherited.
sub __get_object_attributes {
  my $self = shift;
  my $object = shift;
  my @types = (ref $object);
  my %attributes;

  while (my $type = pop(@types)) {
    eval("require $type");
    my $type_bases_name = $type . "::ISA";
    push @types, @$type_bases_name;
    my $attributes_ref = $ATTRIBUTES_OF->{$type};
    for my $key (keys %$attributes_ref) {
      my $value = $attributes_ref->{$key};
      if (not exists $attributes{$key}) {
        $attributes{$key} = $value;
      }
    }
  }
  return \%attributes;
}
# END PATCH

# PATCH To retrieve attributes xml names including inherited.
sub __get_object_names {
  my $object = $_[1];
  my @types = (ref $object);
  my %names;

  while (my $type = pop(@types)) {
    eval("require $type");
    my $type_bases_name = $type . "::ISA";
    push @types, @$type_bases_name;
    my $names_ref = $NAMES_OF{$type};
    for my $key (keys %$names_ref) {
      my $value = $names_ref->{$key};
      if (not exists $names{$key}) {
        $names{$key} = $value;
      }
    }
  }
  return \%names;
}
# END PATCH

# PATCH Method for the client to find objects in the tree based on an a partial
# support of XPath expressions.
sub find {
  my ($self, $xpath_expr) = @_;

  my $parser_node =
      Google::Ads::Common::XPathSAXParser::get_node_from_object($self);

  my @return_list = ();
  if (defined $parser_node) {
    my $node_set = $parser_node->find($xpath_expr);
    foreach my $node ($node_set->get_nodelist()) {
      my $soap_object =
          Google::Ads::Common::XPathSAXParser::get_object_from_node($node);
      if (defined $soap_object) {
        push @return_list, $soap_object;
      }
    }
  }

  return \@return_list;
}
# END PATCH

# PATCH Setting an alias of find -> valueof for backwards compatibility with
# the old version of the client library.
no warnings "once";
*Google::Ads::SOAP::ComplexType::valueof =
    \&Google::Ads::SOAP::ComplexType::find;
# END PATCH

# PATCH Overloading hash casting routine for ComplexType, so all complex types
# can behave as hashes.
use overload (
  '%{}' => 'as_hash_ref',
  fallback => 1,
);
# END PATCH
