package Elasticsearch::Model::Document::Mapper;

use Moose;
use Moose::Util::TypeConstraints;
use List::AllUtils qw/any/;


my %allowable_types_for_mapping_parameter = (
    analyzer               => ["text"],
    coerce                 => ["float", "integer"],
    eager_global_ordinals  => ["keyword","text"],
    fielddata              => ["text"],
    fields                 => ["keyword","text"],
    format                 => ["date"],
    ignore_above           => ["keyword","text"],
    normalizer             => ["keyword"],
    position_increment_gap => ["text"],
    scaling_factor         => ["scaled_float"],
    search_analyzer        => ["text"],
    search_quote_analyzer  => ["text"],
    similarity             => ["text"],
    term_vector            => ["text"],
);

sub _generic_mapping_sub {
    my ($attribute, $type_constraint, $default_type) = @_;

    my $type = ($attribute->type eq 'object' ? '' : $attribute->type)
        || $default_type;
    my $serialization = $attribute->basic_serialization;
    $serialization->{type} = $type;

    # Remove illegal mapping parameters, depending on the 'type' of the field.
    for my $mapping_parameter (keys %$serialization) {
        if (exists $allowable_types_for_mapping_parameter{$mapping_parameter}) {
            my $allowable_types = $allowable_types_for_mapping_parameter{$mapping_parameter};
            delete $serialization->{$mapping_parameter} unless (any { $_ eq $serialization->{type} } @$allowable_types);
        }
    }

    return %$serialization;
}

my %mappings = (
    Any => sub {
        return _generic_mapping_sub(@_, 'text');
    },
    Str => sub {
        return _generic_mapping_sub(@_, 'text');
    },
    Int => sub {
        return _generic_mapping_sub(@_, 'integer');
    },
    Num => sub {
        return _generic_mapping_sub(@_, 'float');
    },
    'Elasticsearch::Model::Types::Location' => sub {
        return _generic_mapping_sub(@_, 'geo_point');
    },
    'Bool' => sub {
        return _generic_mapping_sub(@_, 'boolean');
    },
    'DateTime' => sub {
        return _generic_mapping_sub(@_, 'date');
    },
    'ScalarRef' => sub {
        my ($attribute, $type_constraint) = @_;
        return maptc($attribute, find_type_constraint('Str'));
    },
    'ArrayRef' => sub {
        my ($attribute, $type_constraint) = @_;
        return maptc($attribute, find_type_constraint('Str'));
    },
    'MooseX::Types::Structured::Dict[]' => sub {
        my ($attribute, $type_constraint) = @_;
        my $type        = $attribute->type || 'nested';
        my %constraints = @{$type_constraint->type_constraints};
        my %properties  = ();
        for my $key (keys %constraints) {
            my %inner_constraint =
                maptc($attribute, $constraints{$key}, "$constraints{$key}");
            $properties{$key} = \%inner_constraint;
        }
        my %serialization = maptc($attribute, $type_constraint->parent);
        $serialization{type}       = $type;
        $serialization{properties} = \%properties;
        return %serialization;
    },
    'MooseX::Types::Structured::Optional[]' => sub {
        my ($attribute, $type_constraint) = @_;
        return maptc($attribute, $type_constraint->type_parameter);
    },
    'ArrayRef[]' => sub {
        my ($attribute, $type_constraint) = @_;
        my $type_parameter = $type_constraint->type_parameter;
        return maptc($attribute, $type_parameter);
    },
);

sub maptc {
    my ($attribute, $type_constraint) = @_;
    my $attr_name                     = $attribute->name;
    my $original_type_constraint_name = $type_constraint->name;

    # Get our real constraint out of Maybe before it is reduced to Any
    if ($type_constraint->name =~ /^Maybe/) {
        my $type_constraint_name = $original_type_constraint_name;

    # For Maybe types on a Dict, extract the type_parameter and work with that
    # For Maybe types on other Moose types, just take the base Moose type.
        if ($original_type_constraint_name =~
            /MooseX::Types::Structured::Dict/) {
            $type_constraint = $type_constraint->type_parameter;
        } else {
            ($type_constraint_name = $type_constraint->name) =~
                s/^Maybe\[(.+?)\]/$1/g;
            $type_constraint = find_type_constraint($type_constraint_name);
        }
    }

    $type_constraint //= find_type_constraint('Str');

    (my $name = $type_constraint->name) =~ s/\[.*\]/\[\]/;

    my $sub = $mappings{$name};

    my %ret = ();

    if (not $sub and $type_constraint->has_parent) {

        # Ascend type parent hierarchy if required
        %ret = maptc($attribute, $type_constraint->parent);

    } elsif ($sub) {

        # Or go ahead and call the subref
        %ret = $sub->($attribute, $type_constraint);

    }

    return %ret;
}

__PACKAGE__->meta->make_immutable;

1;
