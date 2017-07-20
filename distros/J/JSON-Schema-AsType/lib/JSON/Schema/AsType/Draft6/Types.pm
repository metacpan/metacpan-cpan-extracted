package JSON::Schema::AsType::Draft6::Types;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: JSON-schema v6 keywords as types
$JSON::Schema::AsType::Draft6::Types::VERSION = '0.4.3';

use strict;
use warnings;

use Type::Utils -all;
use Types::Standard qw/ 
    Str StrictNum HashRef ArrayRef 
    Int
    Dict slurpy Optional Any
    Tuple
    InstanceOf
/;

use Type::Library
    -base,
    -declare => qw(
        PropertyNames
        Contains
        Schema
    );

use List::MoreUtils qw/ all any zip none /;
use List::Util qw/ pairs pairmap reduce uniq /;

use JSON::Schema::AsType;

use JSON::Schema::AsType::Draft4::Types qw/
    Integer Boolean Number String Null Object Array Items
    ExclusiveMinimum ExclusiveMaximum Dependencies Dependency
    Not MultipleOf
/;

__PACKAGE__->meta->add_type( $_ ) for Integer, Boolean, Number, String, Null, Object, Array, Items, ExclusiveMaximum, ExclusiveMinimum;

declare Contains,
    constraint_generator => sub{
        my $type = shift;

        return sub {
            return 1 unless Array->check($_);

            if( Boolean->check($type) ) {
            }

            return any { 
                $type->check($_);
            } @$_;
        }
    };

declare PropertyNames, 
    constraint_generator => sub {
        my $type = shift;
        return sub {
            return 1 unless Object->check($_);

            return 1 if $type eq Any;
            return !keys %$_ if $type eq ~Any;

            return all { $type->check($_) } keys %$_;
        };
    };

declare Dependencies,
    constraint_generator => sub {
        my %deps = @_;

        return reduce { $a & $b } pairmap { Dependency[$a => $b] } %deps;
    };

declare Dependency,
    constraint_generator => sub {
        my( $property, $dep) = @_;

        sub {
            return 1 unless Object->check($_);
            return 1 unless exists $_->{$property};

            my $obj = $_;

            return all { exists $obj->{$_} } @$dep if ref $dep eq 'ARRAY';
            return exists $obj->{$dep} unless ref $dep;

            return $dep->check($_);
        }
    };

declare Properties =>
    constraint_generator => sub {
        my $type = Dict[@_, slurpy Any];

        sub {
            ! Object->check($_) or $type->check($_)
        }
    };

declare Disallow => 
    constraint_generator => sub {
        Not[ shift ];
    };

declare Extends => 
    constraint_generator => sub {
        reduce { $a & $b } @_;
    };

declare DivisibleBy =>
    constraint_generator => sub {
        MultipleOf[shift];
    };

declare Schema, as InstanceOf['Type::Tiny'];

coerce Schema,
    from HashRef,
    via { 
        my $schema = JSON::Schema::AsType->new( draft_version => 6, schema => $_ );

        if ( $schema->validate_schema ) {
            die "not a valid draft6 json schema\n";
        }

        $schema->type 
    };

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JSON::Schema::AsType::Draft6::Types - JSON-schema v6 keywords as types

=head1 VERSION

version 0.4.3

=head1 SYNOPSIS

    use JSON::Schema::AsType::Draft6::Types '-all';

    my $type = Object & 
        Properties[
            foo => Minimum[3]
        ];

    $type->check({ foo => 5 });  # => 1
    $type->check({ foo => 1 });  # => 0

=head1 EXPORTED TYPES

        Null Boolean Array Object String Integer Pattern Number Enum

        OneOf AllOf AnyOf 

        Not

        Minimum ExclusiveMinimum Maximum ExclusiveMaximum MultipleOf

        MaxLength MinLength

        Items AdditionalItems MaxItems MinItems UniqueItems

        PatternProperties AdditionalProperties MaxProperties MinProperties

        Dependencies Dependency

=head2 Schema

Only verifies that the variable is a L<Type::Tiny>. 

Can coerce the value from a hashref defining the schema.

    my $schema = Schema->coerce( \%schema );

    # equivalent to

    $schema = JSON::Schema::AsType::Draft4->new(
        draft_version => 6,
        schema => \%schema;
    )->type;

=head1 AUTHOR

Yanick Champoux <yanick@babyl.dyndns.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2015 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
