package JSON::TypeInference;
use 5.008001;
use strict;
use warnings;

our $VERSION = "1.0.2";

use List::Util qw(first);
use List::UtilsBy qw(partition_by sort_by);

use JSON::TypeInference::Type::Array;
use JSON::TypeInference::Type::Boolean;
use JSON::TypeInference::Type::Maybe;
use JSON::TypeInference::Type::Null;
use JSON::TypeInference::Type::Number;
use JSON::TypeInference::Type::Object;
use JSON::TypeInference::Type::String;
use JSON::TypeInference::Type::Union;
use JSON::TypeInference::Type::Unknown;

use constant ENTITY_TYPE_CLASSES => [
  map { join '::', 'JSON::TypeInference::Type', $_ } qw( Array Boolean Null Number Object String )
];

# [Any] => Type
sub infer {
  my ($class, $dataset) = @_;
  my $dataset_by_type = { partition_by { _infer_type_for($_) } @$dataset };
  my $possible_type_classes = [ keys %$dataset_by_type ];
  my $candidate_types = [ map {
    my $type_class = $_;
    if ($type_class eq 'JSON::TypeInference::Type::Array') {
      my $dataset = $dataset_by_type->{$type_class};
      $class->_infer_array_element_types($dataset);
    } elsif ($type_class eq 'JSON::TypeInference::Type::Object') {
      my $dataset = $dataset_by_type->{$type_class}; # ArrayRef[HashRef[Str, Any]]
      $class->_infer_object_property_types($dataset);
    } else {
      $type_class->new;
    }
  } @$possible_type_classes ];

  if (JSON::TypeInference::Type::Maybe->looks_like_maybe($candidate_types)) {
    my $entity_type = first { ! $_->isa('JSON::TypeInference::Type::Null') } @$candidate_types;
    return JSON::TypeInference::Type::Maybe->new($entity_type);
  } elsif (scalar(@$candidate_types) > 1) {
    return JSON::TypeInference::Type::Union->new(sort_by { $_->name } @$candidate_types);
  } else {
    return $candidate_types->[0] // JSON::TypeInference::Type::Unknown->new;
  }
}

# ArrayRef[ArrayRef[Any]] => JSON::TypeInference::Type::Array
sub _infer_array_element_types {
  my ($class, $dataset) = @_;
  my $elements = [ map { @$_ } @$dataset ];
  my $element_type = $class->infer($elements);
  return JSON::TypeInference::Type::Array->new($element_type);
}

# ArrayRef[HashRef[Str, Any]] => JSON::TypeInference::Type::Object
sub _infer_object_property_types {
  my ($class, $dataset) = @_;
  my $keys = [ map { keys %$_ } @$dataset ]; # ArrayRef[Str]
  my $dataset_by_prop = { map {
    my $prop = $_;
    ($prop => [ map { $_->{$prop} } @$dataset ])
  } @$keys }; # HashRef[Str, ArrayRef[Str]]
  my $prop_types = { map { ($_ => $class->infer($dataset_by_prop->{$_})) } @$keys };
  return JSON::TypeInference::Type::Object->new($prop_types);
}

# Any => Type
sub _infer_type_for {
  my ($data) = @_;
  return (first { $_->accepts($data) } @{ENTITY_TYPE_CLASSES()}) // 'JSON::TypeInference::Type::Unknown';
}

1;
__END__

=encoding utf-8

=head1 NAME

JSON::TypeInference - Inferencing JSON types from given Perl values

=head1 SYNOPSIS

    use JSON::TypeInference;

    my $data = [
      { name => 'yuno' },
      { name => 'miyako' },
      { name => 'nazuna' },
      { name => 'nori' },
    ];
    my $inferred_type = JSON::TypeInference->infer($data); # object[name:string]

=head1 DESCRIPTION

C< JSON::TypeInference > infers the type of JSON values from the given Perl values.

If some candidate types of the given Perl values are inferred, C< JSON::TypeInference > reports the type of it as a union type that consists of all candidate types.

=head1 CLASS METHODS

=over 4

=item C<< infer($dataset: ArrayRef[Any]); # => JSON::TypeInference::Type >>

To infer the type of JSON values from the given values.

Return value is a instance of C< JSON::TypeInference::Type > that means the inferred JSON type.

=back

=head1 LICENSE

Copyright (C) aereal.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

aereal E<lt>aereal@aereal.orgE<gt>

=head1 SEE ALSO

L<JSON::TypeInference::Type>

=cut

