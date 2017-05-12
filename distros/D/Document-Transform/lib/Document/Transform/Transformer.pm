package Document::Transform::Transformer;
BEGIN {
  $Document::Transform::Transformer::VERSION = '1.110530';
}

#ABSTRACT: A document transformer. More than meets the eye. Or not.

use Moose;
use namespace::autoclean;

use Data::DPath('dpathr');
use MooseX::Types::Moose(':all');
use MooseX::Params::Validate;



has $_.'_constraint' =>
(
    is => 'ro',
    isa => 'Moose::Meta::TypeConstraint',
    required => 1,
) for qw/document transform/;


sub transform
{
    my $self = shift;
    my ($document, $transforms) = pos_validated_list
    (
        \@_,
        {isa => $self->document_constraint},
        {isa => ArrayRef[$self->transform_constraint]},
    );

    foreach my $transform(@$transforms)
    {
        foreach my $operation (@{$transform->{operations}})
        {
            my @refs = dpathr($operation->{path})->match($document);
            unless(scalar(@refs))
            {
                if($operation->{path} =~ m#\[|\]|\.|\*|\"|//#)
                {
                    Throwable::Error->throw
                    ({
                        message => 'transform path not found and the path is '.
                            'too complex for simple structure building'
                    });
                }
                else
                {
                    my @paths = split('/', $operation->{path});
                    my $place = $document;
                    for(0..$#paths)
                    {
                        next if $paths[$_] eq '';
                        if($_ == $#paths)
                        {
                            $place->{$paths[$_]} = $operation->{value};
                        }
                        else
                        {
                            $place = \%{$place->{$paths[$_]} = {}};
                        }
                    }
                }
            }
            else
            {
                map { $$_ = $operation->{value}; } @refs;
            }
        }
    }

    return $document;
}

with 'Document::Transform::Role::Transformer';

__PACKAGE__->meta->make_immutable();
1;



=pod

=head1 NAME

Document::Transform::Transformer - A document transformer. More than meets the eye. Or not.

=head1 VERSION

version 1.110530

=head1 SYNOPSIS

    use Document::Transform::Transformer;
    use MyTypeLib(':all');

    my $transformer = Document::Transform::Transformer->new
    (
        document_constraint => Document,
        transform_constraint => Transform,
    );
    my $altered = $transformer->transform($document, $transforms);

=head1 DESCRIPTION

Need a simple transformer that mashes up a transform and a document into
something awesome? This is your module then.

This is the default for Document::Transformer to use. It expects data
structures that align with whatever type constraints are passed into the
constructor that represent a Document and a Transform. It implements the
interface role L<Document::Transform::Role::Transformer>

=head1 PUBLIC_ATTRIBUTES

=head2 document_constraint

    is: ro, isa: Moose::Meta::TypeConstraint, required: 1

The default Transformer must have the constraints supplied to it via
constructor. This constraint should check for whatever is a valid Document for
the backend.

=head2 transform_constraint

    is: ro, isa: Moose::Meta::TypeConstraint, required: 1

The default Transformer must have the constraints supplied to it via
constructor. This constraint should check for whatever is a valid Transform for
the backend.

=head1 PUBLIC_METHODS

=head2 transform

    (Document, ArrayRef[Transform])

transform takes a Document and an array of Transforms and performs the
operations contained with the transforms against the document. Returns the
transformed document.

The type constraints for Document and Transform are stored in the attributes
L</document_constraint> and L</transform_constraint>, respectively.

=head1 AUTHOR

Nicholas R. Perez <nperez@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

