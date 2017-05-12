package Elastic::Model::TypeMap::Default;
$Elastic::Model::TypeMap::Default::VERSION = '0.52';
use strict;
use warnings;

use Elastic::Model::TypeMap::Base qw(
    Elastic::Model::TypeMap::Moose
    Elastic::Model::TypeMap::Structured
    Elastic::Model::TypeMap::Common
    Elastic::Model::TypeMap::Objects
    Elastic::Model::TypeMap::ES
);

1;

=pod

=encoding UTF-8

=head1 NAME

Elastic::Model::TypeMap::Default - The default type map used by Elastic::Model

=head1 VERSION

version 0.52

=head1 DESCRIPTION

Moose's L<type constraints|Moose::Util::TypeConstraints> and introspection
allows Elastic::Model to figure out how to map your data model to the
Elasticsearch backend with the minimum of effort on your part.

What YOU need to do is: B<Be specific about the type constraint for each attribute.>

For instance,  if you have an attribute called C<count>, then specify the
type constraint C<< isa => 'Int' >>.
That way, we know how to define the field in Elasticsearch, and how to deflate
and inflate the value.

Type constraints can inherit their mapping, inflator and deflator from
their parent type-constraints.  For instance, if you were to assign
C<count> the type constraint C<PositiveInt>, although we don't know about that
constraint, we do know about its parent, C<Int>, so we could
still handle the field correctly.

Type maps are used to define:

=over

=item *

what mapping Elastic::Model will generate for each attribute when you
L<create an index|Elastic::Model::Domain::Admin/"create_index()">
or L<update the mapping|Elastic::Model::Domain::Admin/"update_mapping()"> of an
existing index.

=item *

how Elastic::Model will deflate and inflate each attribute when saving or
retrieving docs stored in Elasticsearch.

=back

=head1 BUILT-IN TYPE MAPS

L<Elastic::Model::TypeMap::Default> loads the following type-maps.

=over

=item *

L<Elastic::Model::TypeMap::Moose>

=item *

L<Elastic::Model::TypeMap::Objects>

=item *

L<Elastic::Model::TypeMap::Structured>

=item *

L<Elastic::Model::TypeMap::ES>

=item *

L<Elastic::Model::TypeMap::Common>

=back

=head1 DEFINING YOUR OWN TYPE MAP

See L<Elastic::Model::TypeMap::Base> for instructions on how to define
your own type-map classes.

=head1 TWEAKING YOUR ATTRIBUTE MAPPING

See L<Elastic::Manual::Attributes> for keywords you can use in your
attribute declarations to tweak the mapping of individual fields.

=head1 AUTHOR

Clinton Gormley <drtech@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Clinton Gormley.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: The default type map used by Elastic::Model

