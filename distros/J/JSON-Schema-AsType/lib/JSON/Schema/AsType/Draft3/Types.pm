package JSON::Schema::AsType::Draft3::Types;
our $AUTHORITY = 'cpan:YANICK';
$JSON::Schema::AsType::Draft3::Types::VERSION = '1.0.0';
# ABSTRACT: JSON-schema v3 keywords as types


use strict;
use warnings;

use Type::Utils -all;
use Types::Standard qw/
  InstanceOf
  Str StrictNum HashRef ArrayRef
  Int
  Dict slurpy Optional Any
  Tuple
  /;

use Type::Library
  -base,
  -declare => qw(
  Disallow
  Extends
  DivisibleBy

  Properties

  Dependencies Dependency

  Schema
  );

use List::MoreUtils qw/ all any zip none /;
use List::Util      qw/ pairs pairmap reduce uniq /;

use JSON qw/ to_json from_json /;

use JSON::Schema::AsType;

use JSON::Schema::AsType::Draft4::Types 'Not',
  'Integer',    'MultipleOf',
  'Boolean',    'Number', 'String', 'Null', 'Object', 'Array', 'LaxNumber',
  'LaxInteger', 'LaxString';

__PACKAGE__->meta->add_type($_)
  for Integer, Boolean, Number, String, Null, Object, Array, LaxNumber,
  LaxInteger, LaxString;

declare Dependencies, constraint_generator => sub {
    my %deps = @_;

    return reduce { $a & $b } pairmap { Dependency [ $a => $b ] } %deps;
};

declare Dependency, constraint_generator => sub {
    my ( $property, $dep ) = @_;

    sub {
        return 1 unless Object->check($_);
        return 1 unless exists $_->{$property};

        my $obj = $_;

        return all { exists $obj->{$_} } @$dep if ref $dep eq 'ARRAY';
        return exists $obj->{$dep} unless ref $dep;

        return $dep->check($_);
    }
};

declare Properties => constraint_generator => sub {
    my $type = Dict [ @_, slurpy Any ];

    sub {
        !Object->check($_) or $type->check($_);
    }
};

declare Disallow => constraint_generator => sub {
    Not [shift];
};

declare Extends => constraint_generator => sub {
    reduce { $a & $b } @_;
};

declare DivisibleBy => constraint_generator => sub {
    MultipleOf [shift];
};

declare Schema, as InstanceOf ['Type::Tiny'];

coerce Schema, from HashRef, via {
    my $schema = JSON::Schema::AsType->new( draft => 3, schema => $_ );

    if ( $schema->validate_schema ) {
        die "not a valid draft3 json schema\n";
    }

    $schema->type
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JSON::Schema::AsType::Draft3::Types - JSON-schema v3 keywords as types

=head1 VERSION

version 1.0.0

=head1 DESCRIPTION 

Internal module for L<JSON::Schema:::AsType>. 

=head1 AUTHOR

Yanick Champoux <yanick@babyl.dyndns.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
