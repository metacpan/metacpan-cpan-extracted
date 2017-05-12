package Document::Transform::Role::Transformer;
BEGIN {
  $Document::Transform::Role::Transformer::VERSION = '1.110530';
}

#ABSTRACT: Provides an interface role for Transformers implementations

use Moose::Role;
use namespace::autoclean;




requires qw/ transform document_constraint transform_constraint /;

1;


=pod

=head1 NAME

Document::Transform::Role::Transformer - Provides an interface role for Transformers implementations

=head1 VERSION

version 1.110530

=head1 SYNOPSIS

    package MyTransformer;
    use Moose;
    use MooseX::Params::Validate;
    use MooseX::Types::Moose(':all');
    use MyTypeLib(':all');

    sub document_constraint
    {
        return Document;
    }

    sub transform_constraint
    {
        return Transform;
    }

    sub transform
    {
        my $self = shift;
        my ($doc, $transforms) = validated_list
        (
            \@_,
            {isa => $self->document_constraint},
            {isa => ArrayRef[$self->transform_constraint]},
        );

        #Do transforms here and return document
    }

    with 'Document::Transform::Role::Transformer';
    1;

=head1 DESCRIPTION

Want to implement your own transformer and feed it directly to
L<Document::Transform>? Then this is your role.

Simply implement a suitable transform method along with the constraint methods
or attributes and consume the role.

=head1 ROLE_REQUIRES

=head2 transform

This role requires that you provide the transform method. If merely
substituting your own Transformer implementation, transform will need to take
two arguments, a Document structure and an arrayref of Transform structures
with the expectation that the operations contained with in each Transform are
executed against the Document, and the result returned. The type constraints
for Document and Transform are provided in the L</document_constraint> and
L</transform_constrant> attributes or methods

=head2 document_constraint

In order to constrain the Document appropriately, this attribute or method must
be implemented and must return a L<Moose::Meta::TypeConstraint>.

=head2 transform_constraint

In order to constrain the Transform appropriately, this attribute or method
must be implemented and must return a L<Moose::Meta::TypeConstraint>.

=head1 AUTHOR

Nicholas R. Perez <nperez@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

