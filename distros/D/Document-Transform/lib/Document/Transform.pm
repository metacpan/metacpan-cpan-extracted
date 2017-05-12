package Document::Transform;
BEGIN {
  $Document::Transform::VERSION = '1.110530';
}

#ABSTRACT: Pull and transform documents from a NoSQL backend

use Moose;
use namespace::autoclean;

use Try::Tiny;
use Throwable::Error;
use MooseX::Params::Validate;
use MooseX::Types::Moose(':all');
use Document::Transform::Transformer;
use Moose::Util::TypeConstraints('match_on_type');
use Devel::PartialDump('dump');


has backend =>
(
    is => 'ro',
    does => 'Document::Transform::Role::Backend',
    required => 1,
    handles => 'Document::Transform::Role::Backend',
);


has transformer =>
(
    is => 'ro',
    does => 'Document::Transform::Role::Transformer',
    handles => ['transform'],
    builder => '_build_transformer',
);

sub _build_transformer
{
    my ($self) = @_;
    return Document::Transform::Transformer->new(
        document_constraint => $self->document_constraint,
        transform_constraint => $self->transform_constraint,
    );
}



has post_fetch_callback =>
(
    is => 'ro',
    isa => CodeRef,
    predicate => 'has_post_fetch_callback',
);


sub fetch
{
    my ($self, $key) = pos_validated_list
    (
        \@_,
        {isa => __PACKAGE__},
        {isa => Defined}
    );

    my $transform = $self->fetch_transform_from_key($key);
    unless(defined($transform))
    {
        my $document = $self->fetch_document_from_key($key);
        unless(defined($document))
        {
            Throwable::Error->throw
            ({
                message => 'Unable to fetch anything useful with: '.dump($key)
            });
        }
        if($self->has_post_fetch_callback)
        {
            $self->post_fetch_callback->($document);
        }

        return $document;
    }
    else
    {
        my @transforms = ($transform);
        my $doc;

        do
        {
            $doc = $self->fetch_document_from_transform($transform);
            if($self->transform_constraint->check($doc))
            {
                my @check = map
                {
                    $self->is_same_transform($_, $doc)
                        ? $_
                        : ()
                }
                @transforms;

                if(scalar(@check))
                {
                    Throwable::Error->throw
                    ({
                        message => 'Circular references detected while'.
                        'traversing transform references starting with: '.
                        dump($transform)
                    });
                }
                push(@transforms, $doc);
                $transform = $doc;
            }
        }
        while($self->transform_constraint->check($doc));

        @transforms = reverse @transforms;
        # bottom most transform should be executed first
        my $final = $self->transform($doc, \@transforms);

        if($self->has_post_fetch_callback)
        {
            $self->post_fetch_callback->($final);
        }

        if(wantarray)
        {
            return ($final, @transforms);
        }
        else
        {
            return $final;
        }
    }
}


sub store
{
    my $self = shift;
    my ($item) = pos_validated_list
    (
        \@_,
        {isa =>
            Moose::Util::TypeConstraints::create_type_constraint_union(
                $self->document_constraint,
                $self->transform_constraint
            )
        }
    );

    match_on_type $item =>
    (
        $self->document_constraint => sub { $self->store_document($item) },
        $self->transform_constraint => sub { $self->store_transform($item) },
    );
}


sub check_fetch_document
{
    my ($self, $key) = pos_validated_list
    (
        \@_,
        {isa => __PACKAGE__},
        {isa => Defined}
    );

    return $self->has_document($key);
}


sub check_fetch_transform
{
    my ($self, $key) = pos_validated_list
    (
        \@_,
        {isa => __PACKAGE__},
        {isa => Defined}
    );

    return $self->has_transform($key);
}

__PACKAGE__->meta->make_immutable();
1;



=pod

=head1 NAME

Document::Transform - Pull and transform documents from a NoSQL backend

=head1 VERSION

version 1.110530

=head1 SYNOPSIS

    use Try::Tiny;
    use Document::Transform;
    use Document::Transform::Backend::MongoDB;

    my $backend = Document::Transform::Backend::MongoDB->new(
        host => $ENV{MONGOD}
        database_name => 'foo',
        transform_collection => 'transforms',
        document_collection => 'documents');

    my $transform = Document::Transform->new(backend => $backend);

    my $result;

    try
    {
        $result = $transform->fetch(
            MongoDB::OID->new(value => 'SOME_DOCUMENT'));
    }
    catch
    {
        warn 'Failed to fetch the document';
    }

=head1 DESCRIPTION

Ever need to fetch a document from some NoSQL source, and wanted a way to store
only the specific changes to that document in a separate document and magically
combine the two when you ask for the more specific document? Then this module
will help you get that pony you've always wanted.

Consider the following JSON document:

    {
        "document_id": "QWERTY1",
        "foo": "bar",
        "yarg":
        [
            "one",
            "two",
            "three"
        ],
        "blarg": "sock puppets rock"
    }

This is an awesome, typical document stored in something like MongoDB. Now, what
if we had hundreds of other documents that were all the same except the "blarg"
attribute was slightly different? It would be wasteful to store all of those
whole complete documents. And what if we wanted to update them all? That could
potentially be expensive. So what is the solution? Store a core document, and
store the set of changes to morph it into the more specific or different
document separately. Then when you update the core document, everything else
continues to work without manually touching all of the other documents.

So what does a transform look like? Like this:

    {
        "transform_id": "YTREWQ1",
        "document_id": "QWERTY1",
        "operations":
        [
            {
                "path": "/yarg/*[0]",
                "value": "ONE"
            },
            {
                "path": "/foo",
                "value": "BAR"
            },
            {
                "path": "/qwak/farg",
                "value": { "yarp": 1, "narp": 0 }
            }
        ]
    }

Jumpin' jehosaphat! What is all of that line noise? So, you can see how this
transform references the core document via the document_id attribute. The
transform_id is what we use to fetch this transform. The operations attribute
holds an array of tuples. Each tuple is merely a L<Data::DPath> path
specification and a value to be used at that location. What is a Data::DPath
path? Well, it is like XPath but for data structures. It is some good stuff.

So the first two operations look simple enough. We reference locations that
exist and replace those values with all caps versions, but what about the last
operation? The original document doesn't have anything that matches that path.
Well, you're in luck. If your path is simple enough, the transformer will
create that path for you and dump your value there for you. Now, let me stress
"simple enough." It needs to be straight hashes, no filters, no array access,
etc. So, '/this/path/rocks' will work just fine. '/this/*[4]/path/sucks' will
not work. If you would like it to work, you are more than welcome to implement
your own transformer. Simply consume the interface role
L<Document::Transform::Role::Transformer> and implement the transform method and
pass in an instance and you are set.

Something else this module does is allow you to have transforms reference other
transforms that reference other transforms, and so on until it reaches a source
document. Please be careful that the transforms dont ultimately make a giant
circular linked list that will never resolve to a document. There are checks in
place to throw an exception if a transform has already been seen when
attempting to get a document, but the checks are naive and only look at the
L<Document::Transform::Role::Backend/transform_id_key>. If this key is not
unique in your NoSQL store, then you are screwed. You've been warned.

This module ships with one backend and one transformer implemented but you
aren't married to either if you don't like MongoDB or think the transformer
semantics are subpar. This module and its packages are all very L<Bread::Board>
friendly.

=head1 PUBLIC_ATTRIBUTES

=head2 backend

    is: ro, does: Document::Transform::Role::Backend, required: 1

The backend attribute is required for instantiation of the Document::Transform
object. The backend object is what talks to whichever NoSQL resource to fetch
and store documents and transforms.

You are encouraged to implement your own backends. Simply consume the interface
role L<Document::Transform::Role::Backend> and implement the required methods.

=head2 transformer

    is: ro, does: L<Document::Transform::Role::Transformer>
    builder: '_build_transformer', lazy: 1

The transformer is the object to which transformation responsibilities are
delegated. By default, the L<Document::Transform::Transformer> class is
instantiated when none is provided. Please see its documentation on the
expectations of document and transform formats.

If you would like to implement your own transformer (to support your own
document and transform formats), simply consume the interface role
L<Document::Transform::Role::Transformer> and implement the transform method.

=head2 post_fetch_callback

    is: ro, isa: CodeRef

post_fetch_callback simply provides a way to do additional processing after
the document has been fetched and transform executed. One good use for this is
if validation of the result needs to take place. This coderef is called naked
with a single argument, the final document. Throw an exception if execution
should stop. The return value is discarded.

=head1 PUBLIC_METHODS

=head2 fetch

    (Defined)

fetch performs a transform lookup using the provided key argument, then a
document lookup based information inside the transform(which can recurse as
transforms can reference other transforms until a document is reached). Once it
has both pieces (all of the transforms and the document), it passes them on to
the transformer via the transform method. The result is then passed to the
callback L</post_fetch_callback> before finally being returned.

If for whatever reason there isn't a transform with that key, but there is a
document with that key, the document will be fetched and not transformed. It is
still subject to the L</post_fetch_callback> though.

In list context, the transformed document along with the transforms executed
are returned. Otherwise, just the transformed document is returned.

=head2 store

    (Backend constrained document or transform)

store takes a single item as an argument and depending on the the type
constraints from the backend it will execute the appropriate store method on
the backend. See L<Document::Transform::Role::Backend/document_constraint> and
L<Document::Transform::Role::Backend/transform_constraint> for more information

=head2 check_fetch_document

    (Defined)

A document fetch is attempted with the provided argument. If successful, it
returns true.

=head2 check_fetch_transform

    (Defined)

A transform fetch is attempted with the provided argument. If successful, it
returns true.

=head1 AUTHOR

Nicholas R. Perez <nperez@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

