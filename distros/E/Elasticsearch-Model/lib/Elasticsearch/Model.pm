package Elasticsearch::Model;

use Moose;
use Moose::Exporter;
use Elasticsearch::Model::Index;

our $VERSION = '0.0.1'; # VERSION

# ABSTRACT: Does one thing only: helps to deploy a Moose model and accompanying document classes to Elasticsearch.

=head1 NAME

Elasticsearch::Model

=head1 DESCRIPTION

This module is meant to be used very much like L<ElasticSearchX::Model>, before it was deprecated. In fact, most of the code is borrowed from that module.

All the changes I have made are aimed at two things:

=over

=item 1

Compatibility with L<Elasticsearch 6+|https://www.elastic.co/guide/en/elasticsearch/reference/current/index.html>

=item 2

I<Mapping, period.> Classes to index is all that this distribution does. We do not take data from elasticsearch and wrap it in the document type classes. We do not handle index aliasing, either, which can be quite complicated. For aliasing, however, C<deploy_to> will allow you to specify the name of the index you will be creating, so that you can make the alias more directly.

=back

=head1 SYNOPSIS

This is the simplest use case:

    my $model = MyApplication::Elasticsearch::Model->new;

    $model->deploy;

This is probably the actual use case, in which you have an alias for a versioned index name:

    my $document_types = {
        order => 'Order',
        user  => 'User',
        note  => 'Note',
    };

    my $model = MyApplication::Elasticsearch::Model->new;

    for my $doc_type (keys %$document_types) {
        my $index_object = $model->index($doc_type);
        my $versioned_index_name = $doc_type . "_" . time(); # to get "order_12345859245"
        $index_object->deploy_to(index_name => $versioned_index_name);

        # Get index currently point to by an alias
        my $old_index_name = $model->es->cat->aliases(name => $doc_type, format => 'json')->[0]->{index};

        # Switch the alias to the new index, and remove the alias from the old one.
        $model->es->indices->update_aliases(
            body => {
                actions => [
                    {add => {alias => $doc_type, index => $new_index_name}},
                    (
                        $old_index_name
                        ? ({remove => {alias => $doc_type, index => $old_index_name}})
                        : ()
                    ),
                ],
            },
        );
    }


To do either of the above, you start with a model.

    package MyApplication::Elasticsearch::Model;

    use Moose;
    use Elasticsearch::Model;

    my $document_types = {
        order => 'Order',
        user  => 'User',
        note  => 'Note',
    };

    for my $doc_type (keys %$document_types) {
        index $doc_type => (
            namespace => 'private',
            type      => $document_types->{$doc_type},
            traits    => ["MyApplication::Elasticsearch::DocTrait"],
        );
    }

    normalizer normie => (
        type   => "custom",
        filter => ["lowercase"],
    );

    1;

Elasticsearch 6+ more or less requires one document type per index, so this makes things simple for us. We define one document class per document type, e.g., type C<user> gets document class C<User>.

We will, by default, search for these document classes underneath the model class; in this case, we would search for C<MyApplication::Elasticsearch::Model::User>. You can, however, define a C<document_namespace> in your model class as follows:

    ...

    has_document_namespace "MyApplication::ESDocumentClasses";
    ...

This would mean that we look for C<MyApplication::ESDocumentClasses::User>.

You use C<index> to define the indexes belonging to your model. Here is an example of the Note document class.

    package MyApplication::Elasticsearch::Model::Note;

    use Moose;
    use Elasticsearch::Model::Document;

    has text => (
        is   => 'ro',
        isa  => 'Maybe[Str]',
        type => 'text',
    );

    has author_id => (
        is   => 'ro',
        isa  => 'Maybe[Int]',
        type => 'integer',
    );

    1;

=cut

Moose::Exporter->setup_import_methods(
    with_meta        => [qw(index analyzer tokenizer filter normalizer has_document_namespace)],
    # The class itself does this role
    base_class_roles => ["Elasticsearch::Model::Role"],

    # The class's meta_class does this role.
    # We need class_metaroles here because we do not actually have an object instance
    # at the time the indexes, analyzers, tokenizers, filters and normalizers are constructed.
    # All we have at that time is the Moose::Meta::Class. So the functionality to support
    # that sugar needs to be in a role applied to that Moose::Meta::Class, and not in a role
    # applied to our base class, i.e, whatever is using this class.
    class_metaroles => {class => ['Elasticsearch::Model::Role::Metaclass']},
);


=head1 PUBLIC METHODS

=head2 index

This is an overloaded method that has 2 modes of operation:

=over

=item 1 Adds one single index to the model's metaclass.

This is a compile-time metaclass method that is called when you have the following in your model class:

    index addresses => (
        type => 'Address',
    );

=item 2 Retrieves a single index object from the model instance.

This is a run-time instance method that is called when you do the following:

    my $index_object = $model->index($doc_type);

=back

=cut

sub index {
    my ($self, $name, @args) = @_;
    if (not ref $name) {
        # "Metaclass call to index";
        _add_index_for_name($self, $name, {@args});
        return;
    } else {
        # "Object method call to index";
        # $name is our object instance
        my $index_name = $args[0];
        my $options = $name->meta->get_index($index_name);
        my $index   = Elasticsearch::Model::Index->new(
            name => $index_name,
            %$options,
            model => $name,
            document_namespace => $name->document_namespace,
        );
        return $index;
    }
}

=head2 analyzer

This is a compile-time metaclass method that enables you to declare a custom analyzer using the following syntax in your model class:

    analyzer electro => (
        type      => "custom",
        tokenizer => "standard",
        filter    => ["lowercase", "filtration"],
    );

=cut

sub analyzer {
    my ($self, $name, %args) = @_;
    $self->add_analyzer($name, \%args);
}

=head2 tokenizer

This is a compile-time metaclass method that enables you to declare a custom tokenizer using the following syntax in your model class:

    tokenizer splat => (
        type    => "simple_pattern",
        pattern => "[0123456789]{3}",
    );

=cut

sub tokenizer {
    my ($self, $name, %args) = @_;
    $self->add_tokenizer($name, \%args);
}

=head2 normalizer

This is a compile-time metaclass method that enables you to declare a custom normalizer using the following syntax in your model class:

    normalizer normie => (
        type   => "custom",
        filter => ["lowercase"],
    );

=cut

sub normalizer {
    my ($self, $name, %args) = @_;
    $self->add_normalizer($name, \%args);
}

=head2 filter

This is a compile-time metaclass method that enables you to declare a custom filter using the following syntax in your model class:

    filter filtration => (
        type     => "edge_ngram",
        min_gram => 1,
        max_gram => 24,
    );

=cut

sub filter {
    my ($self, $name, %args) = @_;
    $self->add_filter($name, \%args);
}

=head2 has_document_namespace

This is a compile-time metaclass method that enables you to declare the namespace in which to search for your document classes in your model class:

    has_document_namespace "MyApplication::Elasticsearch::DocumentClasses";

=cut

sub has_document_namespace {
    my ($self, $namespace) = @_;
    $self->document_namespace($namespace);
}

=head1 PRIVATE METHODS

=head2 _apply_namespace

Takes the index name and the namespace, and constructs the namespaced_name.

Used internally, when adding an index to the model's metaclass. See L<Elasticsearch::Model::Role::Metaclass>.

=cut

sub _apply_namespace {
    my ($name, $args) = @_;
    my $namespace = $args->{namespace};
    my $namespaced_name = $name;
    $namespaced_name = $namespace . "_" . $name if $namespace;
    return ($name, $namespaced_name);
}

=head2 _add_index_for_name

Takes the name of an index and some arguments, and adds that index to the model's metaclass. See L<Elasticsearch::Model::Role::Metaclass>.

=cut

sub _add_index_for_name {
    my ($self, $name, $args) = @_;
    my $namespaced_name = $name;
    ($name, $namespaced_name) = _apply_namespace($name,$args);
    $self->add_index($name, {%$args, name => $name, namespaced_name => $namespaced_name});
}

__PACKAGE__->meta->make_immutable;

1;
