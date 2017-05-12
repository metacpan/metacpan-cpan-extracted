package Document::Transform::Role::Backend;
BEGIN {
  $Document::Transform::Role::Backend::VERSION = '1.110530';
}

#ABSTRACT: Interface role to be consumed by backends

use Moose::Role;
use namespace::autoclean;












requires qw/
    fetch_transform_from_key
    fetch_document_from_key
    fetch_transform_from_document
    fetch_document_from_transform
    store_transform
    store_document
    has_document
    has_transform
    is_same_document
    is_same_transform
    document_constraint
    transform_constraint
/;





has $_ . '_id_key' =>
(
    is => 'ro',
    isa => 'Str',
) for qw/document transform reference/;

1;


=pod

=head1 NAME

Document::Transform::Role::Backend - Interface role to be consumed by backends

=head1 VERSION

version 1.110530

=head1 SYNOPSIS

    package MyBackend;
    use Moose;

    sub fetch_document_from_key { }
    sub fetch_transform_from_key { }
    sub fetch_document_from_transform { }
    sub fetch_transform_from_document { }
    sub store_document { }
    sub store_transform { }
    sub has_document { }
    sub has_transform { }
    sub is_same_document { }
    sub is_same_transform { }
    sub document_constraint { }
    sub transform_constraint { }

    with 'Document::Transform::Role::Backend';
    1;

=head1 DESCRIPTION

Want to manage the backend to some other NoSQL database? Then you'll want to
consume this role and implement the needed functions. Generally, the store
functions should take data structures that conform the Types listed in
L</document_constraint>/L</transform_constraint> and the fetch methods should
return those as well.

document_id_key/transform_id_key/reference_id_key are provided to bring more configurability
into the equation when fetching documents and transforms. Backends are free to
ignore these attributes or provide defaults for them. Generally, the backends
should use these attributes.

Transforms and documents should be linked either through the NoSQL database
supported references or soft references that require a second lookup. Either
way, fetch_document_from_transform can either simply access the referenced
document or fetch it from a second lookup, it doesn't really matter.
fetch_transform_from_document is only provided for completeness sake, but isn't
actually used in the implementation. Two-way resolution of references might not
fit your document schema, so an empty subroutine can be safely provided. I
reserve the right to make this two-way communication required in the future.

=head1 ROLE_REQUIRES

=head2 fetch_transform_from_key

This method must accept a key and should return a
Transform defined by L</transform_constraint>

=head2 fetch_document_from_key

This method must accept a key and should return a
Document defined by L</document_constraint>

=head2 fetch_transform_from_document

This method must accept a Document (however that is defined by
L</document_constraint>) and should return a Transform (defined by
L</transform_constraint>)

=head2 fetch_document_from_transform

This method must accept a Transform defined by L</transform_constraint> and
should return a Document defined by L</document_constraint>

=head2 store_transform

This method should accept a Transform defined by L</transform_constraint> and
store it in the backend.

=head2 store_document

This method should accept a Document defined by L</document_constraint> and
store it in the backend.

=head2 has_document

This method must accept a key and return a Bool on if the document exists
in the store.

=head2 has_transform

This method must accept a key and return a Bool on if the transform exists
in the store.

=head2 is_same_document

This method must accept two Document arguments, compare them, and must return
Bool if they are the same

=head2 is_same_transform

This method must accept two Transform arguments, compare them, and must return
Bool if they are the same

=head2 document_constraint

In order for Document::Transform to properly constraint imports on the
front-end, it needs a constraint to check against. This method or attribute
must return a L<Moose::Meta::TypeConstraint> object that constrains those
methods that accept documents as arguments.

=head2 transform_constraint

In order for Document::Transform to properly constraint imports on the
front-end, it needs a constraint to check against. This method or attribute
must return a L<Moose::Meta::TypeConstraint> object that constrains those
methods that accept transforms as arguments.

=head1 PUBLIC_ATTRIBUTES

=head2 document_id_key

    is: ro, isa: Str

This holds the attribute key that should be used when attempting to fetch the
document.

=head2 transform_id_key

    is: ro, isa: Str

This holds the attribute key that should be used when attempting to fetch the
transform.

=head2 reference_id_key

    is: ro, isa: Str

This holds the key that should be used when attempting to fetch a referenced
document from a transform.

=head1 AUTHOR

Nicholas R. Perez <nperez@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

