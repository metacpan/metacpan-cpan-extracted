package Elastic::Model;
$Elastic::Model::VERSION = '0.52';
use Moose 2.06 ();
use Moose::Exporter();
use Carp;
use namespace::autoclean;

Moose::Exporter->setup_import_methods(
    class_metaroles => { class => ['Elastic::Model::Meta::Class::Model'] },
    with_meta       => [
        qw(has_namespace has_typemap override_classes
            has_analyzer has_tokenizer has_filter has_char_filter
            has_unique_index)
    ],
    also => 'Moose',
);

#===================================
sub init_meta {
#===================================
    shift;
    my $meta = Moose->init_meta(@_);
    Moose::Util::apply_all_roles( $meta, 'Elastic::Model::Role::Model' );
}

#===================================
sub has_namespace {
#===================================
    my $meta   = shift;
    my $name   = shift or croak "No namespace name passed to namespace";
    my %params = ( types => @_ );

    my $types = $params{types};
    croak "No types specified for namespace $name"
        unless $types && %$types;

    $meta->add_namespace( $name => \%params );
}

#===================================
sub has_typemap { shift->set_class( 'typemap', @_ ) }
#===================================

#===================================
sub has_unique_index {
#===================================
    my ( $meta, $val ) = @_;
    $meta->unique_index($val);
}

#===================================
sub override_classes {
#===================================
    my $meta = shift;
    my %classes = ref $_[0] eq 'HASH' ? %{ shift() } : @_;
    for ( keys %classes ) {
        croak "Unknown arg for classes ($_)"
            unless $meta->get_class($_);
        $meta->set_class( $_ => $classes{$_} );
    }
}

#===================================
sub has_analyzer {
#===================================
    shift->add_analyzer( shift, ref $_[0] eq 'HASH' ? shift() : {@_} );
}
#===================================
sub has_tokenizer {
#===================================
    shift->add_tokenizer( shift, ref $_[0] eq 'HASH' ? shift() : {@_} );
}
#===================================
sub has_filter {
#===================================
    shift->add_filter( shift, ref $_[0] eq 'HASH' ? shift() : {@_} );
}

#===================================
sub has_char_filter {
#===================================
    shift->add_char_filter( shift, ref $_[0] eq 'HASH' ? shift() : {@_} );
}

1;

# ABSTRACT: A NoSQL document store with full text search for Moose objects using Elasticsearch as a backend.

__END__

=pod

=encoding UTF-8

=head1 NAME

Elastic::Model - A NoSQL document store with full text search for Moose objects using Elasticsearch as a backend.

=head1 VERSION

version 0.52

=head1 SYNOPSIS

    package MyApp;

    use Elastic::Model;

    has_namespace 'myapp' => {
        user => 'MyApp::User',
        post => 'MyApp::Post'
    };

    has_typemap 'MyApp::TypeMap';

    # Setup custom analyzers

    has_filter 'edge_ngrams' => (
        type     => 'edge_ngram',
        min_gram => 2,
        max_gram => 10
    );

    has_analyzer 'edge_ngrams' => (
        tokenizer => 'standard',
        filter    => [ 'standard', 'lowercase', 'edge_ngrams' ]
    );

    no Elastic::Model;

=head1 DESCRIPTION

Elastic::Model is a framework to store your Moose objects, which uses
Elasticsearch as a NoSQL document store and flexible search engine.

It is designed to make it easy to start using Elasticsearch with minimal extra
code, but allows you full access to the rich feature set available in
Elasticsearch as soon as you are ready to use it.

=head1 FUTURE OF ELASTIC::MODEL - PLEASE READ AND COMMENT

Hi all users of Elastic::Model

Elasticsearch 2.0.0 is out, and Elastic::Model doesn't support it.
In fact, Elastic::Model doesn't support a number of things from
Elasticsearch 1.x either. I apologise for neglecting this module.

My feeling is that Elastic::Model tries to do way too much.
Like many frameworks, it ties you into doing things in a
particular way, which may or may not make sense for your use
case. Most people who use Elastic::Model seem to use a
subset of the functionality, and then talk to Elasticsearch
directly the rest of the time.

I don't think it makes sense to just update the code for
2.x, it needs a complete rethink.

=head2 TELL ME HOW YOU USE IT

Please could you add comments to
L<this issue|https://github.com/clintongormley/Elastic-Model/issues/42>
explaining what bits you find useful, what bits you never use,
and what bits you find annoying. Perhaps the code can be split
out into smaller more useful chunks.

=head1 INTRODUCTION TO Elastic::Model

If you are not familiar with L<Elastic::Model>, you should start by reading
L<Elastic::Manual::Intro>.

The rest of the documentation on this page explains how to use the
L<Elastic::Model> module itself.

=head1 BACKWARDS COMPATIBILITY BREAK

B<NOTE:> This version of Elastic::Model uses L<Search::Elasticsearch>
and is intended for Elasticsearch 1.x. However, it can be used
with Elasticsearch 0.90.x in "compatibility mode". Elasticsearch 2.x is
not supported.

B<< You can no longer use the old L<Search::Elasticsearch::Compat>. >>
See L<Elastic::Manual::Delta> for instructions.

For a version of Elastic::Model which uses Search::Elasticsearch::Compat
please see L<https://metacpan.org/release/DRTECH/Elastic-Model-0.28>.

=head1 USING ELASTIC::MODEL

Your application needs a C<model> class to handle the relationship between
your object classes and the Elasticsearch cluster.

Your model class is most easily defined as follows:

    package MyApp;

    use Elastic::Model;

    has_namespace 'myapp' => {
        user => 'MyApp::User',
        post => 'MyApp::Post'
    };

    no Elastic::Model;

This applies L<Elastic::Model::Role::Model> to your C<MyApp> class,
L<Elastic::Model::Meta::Class::Model> to C<MyApp>'s metaclass and exports
functions which help you to configure your model.

Your model must define at least one L<namespace|Elastic::Manual::Terminology/Namespace>,
which tells Elastic::Model which
L<type|Elastic::Manual::Terminology/Type> (like a table in a DB) should be
handled by which of your classes.  So the above declaration says:

I<"For all L<indices|Elastic::Model::Terminology/Index> which belong to namespace
C<myapp>, objects of class C<MyApp::User> will be stored under the
L<type|Elastic::Model::Terminology/Type> C<user> in Elasticsearch.">

=head2 Custom TypeMap

Elastic::Model uses a L<TypeMap|Elastic::Model::TypeMap::Default> to figure
out how to inflate and deflate your objects, and how to configure them
in Elasticsearch.

You can specify your own TypeMap using:

    has_typemap 'MyApp::TypeMap';

See L<Elastic::Model::TypeMap::Base> for instructions on how to define
your own type-map classes.

=head2 Custom unique key index

If you have attributes whose values are
L<unique|Elastic::Manual::Attributes::Unique>, then you can customize the index
where these unique values are stored.

    has_unique_index 'myapp_unique';

The default value is C<unique_key>.

=head2 Custom analyzers

Analysis is the process of converting full text into C<terms> or C<tokens> and
is one of the things that gives full text search its power.  When storing text
in the Elasticsearch index, the text is first analyzed into terms/tokens.
Then, when searching, search keywords go through the same analysis process
to produce the terms/tokens which are then searched for in the index.

Choosing the right analyzer for each field gives you enormous control over
how your data can be queried.

There are a large number of built-in analyzers available, but frequently
you will want to define custom analyzers, which consist of:

=over

=item *

zero or more character filters

=item *

a tokenizer

=item *

zero or more token filters

=back

L<Elastic::Model> provides sugar to make it easy to specify custom analyzers:

=head3 has_char_filter

Character filters can change the text before it gets tokenized, for instance:

    has_char_filter 'my_mapping' => (
        type        => 'mapping',
        mappings    => ['ph=>f','qu=>q']
    );

See L<Elastic::Model::Meta::Class::Model/Default character filters> for a list
of the built-in character filters.

=head3 has_tokenizer

A tokenizer breaks up the text into individual tokens or terms. For instance,
the C<pattern> tokenizer could be used to split text using a regex:

    has_tokenizer 'my_word_tokenizer' => (
        type        => 'pattern',
        pattern     => '\W+',          # splits on non-word chars
    );

See L<Elastic::Model::Meta::Class::Model/Default tokenizers> for a list
of the built-in tokenizers.

=head3 has_filter

Any terms/tokens produced by the L</"has_tokenizer"> can the be passed through
multiple token filters.  For instance, each term could be broken down into
"edge ngrams" (eg 'foo' => 'f','fo','foo') for partial matching.

    has_filter 'my_ngrams' => (
        type        => 'edge_ngram',
        min_gram    => 1,
        max_gram    => 10,
    );

See L<Elastic::Model::Meta::Class::Model/Default token filters> for a list
of the built-in character token filters.

=head3 has_analyzer

Custom analyzers can be defined by combining character filters, a tokenizer and
token filters, some of which could be built-in, and some defined by the
keywords above.

For instance:

    has_analyzer 'partial_word_analyzer' => (
        type        => 'custom',
        char_filter => ['my_mapping'],
        tokenizer   => ['my_word_tokenizer'],
        filter      => ['lowercase','stop','my_ngrams']
    );

See L<Elastic::Model::Meta::Class::Model/Default analyzers> for a list
of the built-in analyzers.

=head2 Overriding Core Classes

If you would like to override any of the core classes used by L<Elastic::Model>,
then you can do so as follows:

    override_classes (
        domain  => 'MyApp::Domain',
        store   => 'MyApp::Store'
    );

The defaults are:

=over

=item *

C<namespace> C<-----------> L<Elastic::Model::Namespace>

=item *

C<domain> C<--------------> L<Elastic::Model::Domain>

=item *

C<store> C<---------------> L<Elastic::Model::Store>

=item *

C<view> C<----------------> L<Elastic::Model::View>

=item *

C<scope> C<---------------> L<Elastic::Model::Scope>

=item *

C<results> C<-------------> L<Elastic::Model::Results>

=item *

C<cached_results> C<------> L<Elastic::Model::Results::Cached>

=item *

C<scrolled_results> C<----> L<Elastic::Model::Results::Scrolled>

=item *

C<result> C<--------------> L<Elastic::Model::Result>

=item *

C<bulk> C<----------------> L<Elastic::Model::Bulk>

=back

=head1 SEE ALSO

=over

=item *

L<Elastic::Model::Role::Model>

=item *

L<Elastic::Manual>

=item *

L<Elastic::Doc>

=back

=head1 AUTHOR

Clinton Gormley <drtech@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Clinton Gormley.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
