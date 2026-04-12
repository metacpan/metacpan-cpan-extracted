package JSON::Schema::AsType::Draft7::Types;
our $AUTHORITY = 'cpan:YANICK';
$JSON::Schema::AsType::Draft7::Types::VERSION = '1.0.0';
# ABSTRACT: Type::Tiny types for draft 7 schemas


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
  Schema
  );

use List::MoreUtils qw/ all any zip none /;
use List::Util      qw/ pairs pairmap reduce uniq /;

use JSON::Schema::AsType;

# __PACKAGE__->meta->add_type( $_ ) for Integer, Boolean, Number, String, Null, Object, Array, Items, ExclusiveMaximum, ExclusiveMinimum;

declare If => constraint_generator => sub {
    my ( $if, $then, $else ) = @_;

    return sub {
        $if->check($_) ? $then->check($_) : $else->check($_);
    }

};

declare Schema, as InstanceOf ['Type::Tiny'];

coerce Schema, from HashRef, via {
    my $schema = JSON::Schema::AsType->new( draft => 7, schema => $_ );

    if ( $schema->validate_schema ) {
        die "not a valid draft7 json schema\n";
    }

    $schema->type
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JSON::Schema::AsType::Draft7::Types - Type::Tiny types for draft 7 schemas

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
