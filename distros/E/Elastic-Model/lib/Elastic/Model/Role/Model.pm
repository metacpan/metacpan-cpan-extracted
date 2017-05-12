package Elastic::Model::Role::Model;
$Elastic::Model::Role::Model::VERSION = '0.52';
use Moose::Role;
use Carp;
use Elastic::Model::Types qw(ES);
use Search::Elasticsearch 1.20 ();
use Class::Load qw(load_class);
use Moose::Util qw(does_role);
use MooseX::Types::Moose qw(:all);
use Elastic::Model::UID();
use Elastic::Model::Deleted();
use Scalar::Util qw(blessed refaddr weaken);
use List::MoreUtils qw(uniq);
use JSON();
our $JSON = JSON->new->canonical->utf8;

use namespace::autoclean;
my @wrapped_classes = qw(
    domain  namespace      store   view     scope
    results cached_results scrolled_results result  bulk
);

#===================================
sub BUILD {
#===================================
    my $self = shift;
    my $es   = $self->es;
    if ( $es->isa('Search::Elasticsearch::Client::0_90::Direct') ) {
        $self->_set_result_class(
            $self->_wrap_class('Elastic::Model::0_90::Result') );
        $self->_set_store_class(
            $self->_wrap_class('Elastic::Model::0_90::Store') );
    }
    $self->doc_class_wrappers;
    return $self;

}

for my $class (@wrapped_classes) {
#===================================
    has "${class}_class" => (
#===================================
        isa     => Str,
        is      => 'ro',
        lazy    => 1,
        writer  => "_set_${class}_class",
        default => sub { shift->wrap_class($class) }
    );
}

#===================================
has 'typemap' => (
#===================================
    is      => 'ro',
    isa     => Str,
    default => sub { shift->wrap_class('typemap') }
);

#===================================
has [ 'deflators', 'inflators' ] => (
#===================================
    isa     => HashRef,
    is      => 'ro',
    default => sub { {} }
);

#===================================
has 'store' => (
#===================================
    does    => 'Elastic::Model::Role::Store',
    is      => 'ro',
    lazy    => 1,
    builder => '_build_store'
);

#===================================
has 'es' => (
#===================================
    isa     => ES,
    is      => 'ro',
    lazy    => 1,
    builder => '_build_es',
    coerce  => 1,
);

#===================================
has '_unique_index' => (
#===================================
    isa     => Str,
    is      => 'ro',
    lazy    => 1,
    builder => '_build_unique_index',
);

#===================================
has 'doc_class_wrappers' => (
#===================================
    is      => 'ro',
    isa     => HashRef,
    traits  => ['Hash'],
    lazy    => 1,
    builder => '_build_doc_class_wrappers',
    handles => {
        class_for   => 'get',
        knows_class => 'exists'
    }
);

#===================================
has 'namespaces' => (
#===================================
    is      => 'ro',
    isa     => HashRef,
    traits  => ['Hash'],
    builder => '_build_namespaces',
    handles => { namespace => 'get' }
);

#===================================
has '_domain_cache' => (
#===================================
    isa     => HashRef,
    is      => 'bare',
    traits  => ['Hash'],
    default => sub { {} },

    # TODO clear domain cache when changing indices/aliases?
    handles => {
        _get_domain   => 'get',
        _cache_domain => 'set',
    },
);

#===================================
has '_domain_namespace' => (
#===================================
    is      => 'ro',
    isa     => HashRef,
    traits  => ['Hash'],
    lazy    => 1,
    builder => '_build_domain_namespace',
    clearer => 'clear_domain_namespace',
    handles => { _get_domain_namespace => 'get', }
);

#===================================
has 'current_scope' => (
#===================================
    is        => 'rw',
    isa       => 'Elastic::Model::Scope',
    weak_ref  => 1,
    clearer   => 'clear_current_scope',
    predicate => 'has_current_scope',
);

#===================================
sub _build_store { $_[0]->store_class->new( es => $_[0]->es ) }
sub _build_es { Search::Elasticsearch->new( client => '1_0::Direct' ) }
#===================================

#===================================
sub _build_unique_index {
#===================================
    my $self  = shift;
    my $index = Class::MOP::class_of($self)->unique_index;
    $self->store->bootstrap_uniques( index => $index );
    return $index;
}

#===================================
sub _build_namespaces {
#===================================
    my $self = shift;
    my $conf = Class::MOP::class_of($self)->namespaces;
    my %namespaces;
    my $ns_class = $self->namespace_class;
    while ( my ( $name, $args ) = each %$conf ) {
        my $types = $args->{types};
        my %classes
            = map { $_ => $self->class_for( $types->{$_} ) } keys %$types;
        $namespaces{$name} = $ns_class->new(
            name          => $name,
            types         => \%classes,
            fixed_domains => $args->{fixed_domains} || []
        );
    }
    \%namespaces;
}

#===================================
sub _build_doc_class_wrappers {
#===================================
    my $self       = shift;
    my $namespaces = Class::MOP::class_of($self)->namespaces;
    +{  map { $_ => $self->wrap_doc_class($_) }
        map { values %{ $_->{types} } } values %$namespaces
    };
}

#===================================
sub _build_domain_namespace {
#===================================
    my $self       = shift;
    my $namespaces = $self->namespaces;
    my %domains;

    for my $name ( keys %$namespaces ) {
        my $ns = $namespaces->{$name};
        for my $domain ( $namespaces->{$name}->all_domains ) {
            croak "Cannot map domain ($domain) to namespace ($name). "
                . "It is already mapped to namespace ("
                . $domains{$domain}->name . ")."
                if $domains{$domain};
            $domains{$domain} = $ns;
        }
    }
    \%domains;
}

#===================================
sub namespace_for_domain {
#===================================
    my ( $self, $domain ) = @_;
    my $ns;
    $ns = $self->_get_domain_namespace($domain) and return $ns;
    $self->clear_domain_namespace;
    $self->_get_domain_namespace($domain)
        or croak "No namespace found for domain ($domain). ";
}

#===================================
sub all_live_indices {
#===================================
    my $self = shift;
    return map { $_->all_live_indices } values %{ $self->namespaces };
}

#===================================
sub wrap_doc_class {
#===================================
    my $self  = shift;
    my $class = shift;

    load_class($class);

    croak "Class ($class) does not do Elastic::Model::Role::Doc. "
        . "Please add : use Elastic::Doc;\n\n"
        unless Moose::Util::does_role( $class, 'Elastic::Model::Role::Doc' );

    $self->_wrap_class($class);
}

#===================================
sub wrap_class {
#===================================
    my $self  = shift;
    my $name  = shift || '';
    my $class = $self->meta->get_class($name)
        or croak "Unknown class for ($name)";

    $self->_wrap_class($class);
}

#===================================
sub _wrap_class {
#===================================
    my $self  = shift;
    my $class = shift;
    load_class($class);

    my $meta
        = Moose::Meta::Class->create(
        Class::MOP::class_of($self)->wrapped_class_name($class),
        superclasses => [$class] );

    weaken( my $weak_model = $self );
    $meta->add_method( model          => sub {$weak_model} );
    $meta->add_method( original_class => sub {$class} );
    $meta->make_immutable;

    return $meta->name;
}

#===================================
sub domain {
#===================================
    my $self = shift;
    my $name = shift or croak "No domain name passed to domain()";
    my $domain;

    $domain = $self->_get_domain($name) and return $domain;
    my $ns = $self->namespace_for_domain($name)
        or croak "Unknown domain name ($name)";

    $domain = $self->domain_class->new(
        name      => $name,
        namespace => $ns
    );
    return $self->_cache_domain( $name => $domain );
}

#===================================
sub view { shift->view_class->new(@_) }
#===================================

#===================================
sub new_scope {
#===================================
    my $self = shift;
    my @args
        = $self->has_current_scope ? ( parent => $self->current_scope ) : ();
    $self->current_scope( $self->scope_class->new(@args) );
}

#===================================
sub detach_scope {
#===================================
    my ( $self, $scope ) = @_;
    my $current = $self->current_scope;
    return unless $current && refaddr($current) eq refaddr($scope);
    my $parent = $scope->parent;
    return $self->clear_current_scope unless $parent;
    $self->current_scope($parent);
}

#===================================
sub get_doc {
#===================================
    my ( $self, %args ) = @_;
    my $uid = $args{uid}
        or croak "No UID passed to get_doc()";

    my $ns     = $self->namespace_for_domain( $uid->index );
    my $scope  = $self->current_scope;
    my $source = $args{source};

    my $object;
    $object = $scope->get_object( $ns->name, $uid )
        if $scope && !$source;

    unless ($object) {
        unless ( $source || $uid->from_store ) {
            $source = $self->get_doc_source(%args) or return;
        }
        my $class = $ns->class_for_type( $uid->type );
        $object = $class->meta->new_stub( $uid, $source );
        $object = $scope->store_object( $ns->name, $object )
            if $scope;
    }
    $object;
}

#===================================
sub get_doc_source {
#===================================
    my ( $self, %args ) = @_;

    my $uid = delete $args{uid};
    my $result = $self->store->get_doc( $uid, %args ) or return;
    $uid->update_from_store($result);
    return $result->{_source};
}

#===================================
sub new_partial_doc {
#===================================
    my ( $self, %args ) = @_;
    my $uid = $args{uid}
        or croak "No UID passed to new_partial_doc()";

    my $source = $args{partial_source}
        or croak "No (partial_source) passed to new_partial_doc()";

    my $ns = $self->namespace_for_domain( $uid->index );

    my $class = $ns->class_for_type( $uid->type );
    return $class->meta->new_stub( $uid, $source );
}

#===================================
sub doc_exists {
#===================================
    my ( $self, %args ) = @_;
    my $uid = delete $args{uid}
        or croak "No UID passed to doc_exists()";
    return $self->store->doc_exists( $uid, %args );
}

#===================================
sub save_doc {
#===================================
    my ( $self, %args ) = @_;

    my $doc = delete $args{doc};
    my $uid = $doc->uid;

    croak "Cannot save partial doc type ("
        . $uid->type
        . ") id ("
        . $uid->id . ")"
        if $uid->is_partial;

    my $data = $self->deflate_object($doc);

    my $action
        = ( $uid->from_store or $uid->id and defined $args{version} )
        ? 'index_doc'
        : 'create_doc';

    my $on_unique   = delete $args{on_unique};
    my $on_conflict = delete $args{on_conflict};

    my $unique = $self->_update_unique_keys( $doc, $action, $on_unique )
        or return;

    my $result = eval { $self->store->$action( $uid, $data, %args ) } or do {
        my $error = $@;
        $unique->{rollback}->();
        return $self->_handle_error( $error, $on_conflict, $doc );
    };

    $unique->{commit}->();

    $uid->update_from_store($result);
    $doc->_set_source($data);

    my $scope = $self->current_scope
        or return $doc;

    my $ns = $self->namespace_for_domain( $uid->index );
    return $scope->store_object( $ns->name, $doc );
}

my $noops = {
    commit   => sub { },
    rollback => sub { }
};

#===================================
sub _update_unique_keys {
#===================================
    my ( $self, $doc, $action, $on_unique ) = @_;
    my $meta    = Class::MOP::class_of($doc);
    my $uniques = $meta->unique_keys
        or return $noops;

    my $from_store = $doc->uid->from_store;

    croak "Cannot overwrite a new doc of class ("
        . $doc->original_class
        . ") because it has unique keys"
        if $action eq 'index_doc' and not $from_store;

    my ( %old, %new );
    for my $key ( keys %$uniques ) {
        my $unique_key = $uniques->{$key};
        my $new        = $doc->$key;
        no warnings 'uninitialized';

        if ($from_store) {
            my $old = $doc->_source->{$key};
            next if $old eq $new;
            $old{$unique_key} = $old if length $old;
        }

        $new{$unique_key} = $new if length $new;
    }

    my $uniq  = $self->_unique_index;
    my $store = $self->store;

    if ( my %failed
        = $store->create_unique_keys( index => $uniq, keys => \%new ) )
    {
        if ($on_unique) {
            $on_unique->( $doc, \%failed );
            return;
        }
        croak "Unique keys already exist: "
            . join( ', ', map { $_ . '/' . $failed{$_} } sort keys %failed );

    }
    return {
        commit => sub {
            $store->delete_unique_keys( index => $uniq, keys => \%old );
        },
        rollback => sub {
            $store->delete_unique_keys( index => $uniq, keys => \%new );
        },
    };
}

#===================================
sub _handle_error {
#===================================
    my ( $self, $error, $on_conflict, $original ) = @_;
    $error ||= 'Unknown error';

    die $error
        unless $on_conflict
        and $error->is('Conflict');

    my $new;
    if ( my $current_version = $error->{vars}{current_version} ) {
        my $uid = Elastic::Model::UID->new(
            %{ $original->uid->read_params },
            version    => $current_version,
            from_store => 1
        );
        $new = $self->get_doc( uid => $uid );

    }
    else {
        $new = $self->get_doc( uid => $original->uid->clone );
    }

    $on_conflict->( $original, $new );

    return;
}

#===================================
sub delete_doc {
#===================================
    my ( $self, %args ) = @_;
    my $uid = delete $args{uid}
        or croak "No UID passed to delete_doc()";

    my $unique = $self->_delete_unique_keys($uid);
    my $result = $self->store->delete_doc( $uid, %args )
        or return;
    $unique->{commit}->();

    $uid->update_from_store($result);

    if ( my $scope = $self->current_scope ) {
        my $ns = $self->namespace_for_domain( $uid->index );
        $scope->delete_object( $ns->name, $uid );
    }
    return $uid;
}

#===================================
sub _delete_unique_keys {
#===================================
    my ( $self, $uid ) = @_;

    my $doc = $self->get_doc( uid => $uid, ignore => 404 )
        or return $noops;

    my $meta = Class::MOP::class_of($doc);
    my $uniques = $meta->unique_keys or return $noops;

    my %old;
    for my $key ( keys %$uniques ) {
        no warnings 'uninitialized';
        my $old = $doc->_source->{$key};
        $old{ $uniques->{$key} } = $old if length $old;
    }
    my $uniq  = $self->_unique_index;
    my $store = $self->store;
    return {
        commit => sub {
            $store->delete_unique_keys(
                index => $uniq,
                keys  => \%old
            );
        },
    };
}

#===================================
sub bulk { shift->bulk_class->new(@_) }
#===================================

#===================================
sub search { shift->store->search(@_) }
#===================================

#===================================
sub deflate_object {
#===================================
    my $self   = shift;
    my $object = shift or die "No object passed to deflate()";
    my $class  = blessed $object
        or die "deflate() can only deflate objects";
    $self->deflator_for_class($class)->($object);
}

#===================================
sub deflator_for_class {
#===================================
    my $self  = shift;
    my $class = shift;
    $class = $self->class_for($class) || $class;
    return $self->deflators->{$class} ||= do {
        die "Class $class is not an Elastic class."
            unless does_role( $class, 'Elastic::Model::Role::Doc' );
        $self->typemap->class_deflator($class);
    };
}

#===================================
sub inflate_object {
#===================================
    my $self   = shift;
    my $object = shift or die "No object passed to inflate()";
    my $hash   = shift or die "No hash pashed to inflate()";
    $self->inflator_for_class( blessed $object)->( $object, $hash );
}

#===================================
sub inflator_for_class {
#===================================
    my $self  = shift;
    my $class = shift;
    $class = $self->class_for($class) || $class;
    return $self->inflators->{$class} ||= do {
        die "Class $class is not an Elastic class."
            unless does_role( $class, 'Elastic::Model::Role::Doc' );
        $self->typemap->class_inflator($class);
    };
}

#===================================
sub map_class {
#===================================
    my $self  = shift;
    my $class = shift;
    $class = $self->class_for($class) || $class;

    die "Class $class is not an Elastic class."
        unless does_role( $class, 'Elastic::Model::Role::Doc' );

    my $meta = $class->original_class->meta;

    my %mapping = (
        %{ $meta->mapping },
        $self->typemap->class_mapping($class),
        dynamic           => 'strict',
        _timestamp        => { enabled => 1, path => 'timestamp' },
        numeric_detection => 1,
    );
    delete $mapping{type};
    return \%mapping;
}

#===================================
sub json {$JSON}
#===================================

1;

=pod

=encoding UTF-8

=head1 NAME

Elastic::Model::Role::Model - The role applied to your Model

=head1 VERSION

version 0.52

=head1 SYNOPSIS

    use MyApp;

    my $es         = Search::Elasticsearch->new(
        client => '1_0::Direct',
        nodes  => 'es.domain.com:9200'
    );
    my $model      = MyApp->new( es => $es );

    my $namespace  = $model->namespace('myapp');
    my $domain     = $model->domain('my_domain');
    my $view       = $model->view();

    my $scope      = $model->new_scope;

=head1 DESCRIPTION

A "Model" is the Boss Object, which ties an instance of your application to
a particular Elasticsearch cluster. You can have multiple instances of your
Model class which connect to different clusters.

C<Elastic::Model::Role::Model> is applied to your Model class when you
include the line:

    use Elastic::Model;

See L<Elastic::Model> for more about how to setup your Model class.

=head1 COMMONLY USED METHODS

=head2 new()

Usually, the only parameter that you need to pass to C<new()> is C<es>,
which contains your L<Search::Elasticsearch> connection.

    $es    = Search::Elasticsearch->new( nodes => 'es1.domain.com:9200' );
    $model = MyApp->new( es => $es );

If the C<es> parameter is omitted, then it will default to a L<Search::Elasticsearch>
connection to C<localhost:9200>.

    $model = MyApp->new();   # localhost:9200

=head2 namespace()

    $namespace = $model->namespace($name);

Returns the L<Elastic::Model::Namespace> instance corresponding to
C<$name>. The namespace must have been configured via
L<Elastic::Model/has_namespace>.

Use a C<$namespace> to create, delete and update
L<indices|Elastic::Manual::Terminology/Index> and
L<index aliases|Elastic::Manual::Terminology/Alias>.

=head2 domain()

    $domain = $model->domain($name);

Returns an L<Elastic::Model::Domain> instance where C<$name> is the name
of an L<index|Elastic::Manual::Terminology/Index> or
L<index alias|Elastic::Manual::Terminology/Alias> (which points at a single
index) and is known to one of the L</namespaces>.

Use a C<$domain> to create, retrieve, update or delete individual
objects/documents.

=head2 view()

    $view = $model->view(%args);

Creates a new L<Elastic::Model::View> instance. Any args are passed on to
L<Elastic::Model::View/"new()">.

Use a C<$view> to query your documents.  Views can be multi-domain and
multi-type.

=head2 new_scope()

    $scope = $model->new_scope();

Creates a new L<Elastic::Model::Scope> instance (in-memory cache). If there is
an existing scope, then the new scope inherits from the existing scope.

    $scope = $model->new_scope();   # scope_1
    $scope = $model->new_scope();   # scope_2, inherits from scope_1
    undef $scope;                   # scope_2 and scope_1 are destroyed

Scopes are optional unless you have attributes which are weakened.

See L<Elastic::Model::Scoping> and L<Elastic::Model::Scope> to read more about
how scopes work.

=head1 OTHER METHODS AND ATTRIBUTES

These methods and attributes, while public, are usually used only by internal
modules. They are documented here for completeness.

=head2 CRUD

=head3 get_doc()

Normally, you want to use L<Elastic::Model::Domain/"get()"> rather than this
method.

    $doc = $model->get_doc(uid => $uid);
    $doc = $model->get_doc(uid => $uid, ignore => 404, ...);

C<get_doc()> tries to retrieve the object corresponding to the
L<$uid|Elastic::Model::UID>, first from the L</current_scope()> (if there is one)
or from any of its parents. Failing that, it tries to retrieve the doc
from the L</store>. If it finds the doc, then
it stores it in the current scope (again, if there is one), otherwise it
throws an error.

C<get_doc()> also accepts an optional C<$source> parameter which is
used internally for inflating search results.
See L<Elastic::Model::Scope> for a more detailed explanation.

Any other args are passed on to L<Elastic::Model::Store/get_doc()>.

=head3 get_doc_source()

    $doc = $model->get_doc_source(uid => $uid);
    $doc = $model->get_doc_source(uid => $uid, ignore => 404, ...);

Calls L<Elastic::Model::Store/"get_doc()"> and returns the raw source hashref
as stored in Elasticsearch for the doc with the corresponding
L<$uid|Elastic::Model::UID>. Throws an error if it doesn't exist.

Any other args are passed on to L<Elastic::Model::Store/get_doc()>.

=head3 doc_exists()

    $bool = $model->doc_exists( uid => $uid, %args );

Calls L<Elastic::Model::Role::Store/doc_exists()> to check whether the doc
exists.

=head3 save_doc()

Normally, you want to use L<Elastic::Model::Role::Doc/"save()"> rather than this
method.

    $doc = $model->save_doc(doc => $doc, %args);

Saves C<$doc> to Elasticsearch by calling
L<Elastic::Model::Store/"index_doc()"> (if the C<$doc> was originally loaded
from Elasticsearch), or L<Elastic::Model::Store/"create_doc()">, which
will throw an error if a doc with the same C<index|type|id> already
exists.

Any C<%args> are passed on to L<index_doc()|Elastic::Model::Store/"index_doc()"> or
L<create_doc()|Elastic::Model::Store/"create_doc()">.

If there is a L</current_scope()> then the object is also stored there.

Also see the L<Elastic::Model::Role::Doc/on_conflict> and
L<Elastic::Model::Role::Doc/on_unique> parameters.

=head3 delete_doc()

    $uid = $model->delete_doc(uid => $uid, ignore => 404, ...)

Calls L<Elastic::Model::Store/delete_doc()> and returns the updated
L<Elastic::Model::UID> object. Throws an error if it doesn't exist.
If there is a L</current_scope()> then an L<Elastic::Model::Deleted> object
is stored there.

=head3 search()

Normally, you want to use L<Elastic::Model::View> rather than this
method.

    $results = $model->search(%args)

Passes C<%args> through to L<Elastic::Model::Store/"search()">

=head3 new_partial_doc()

    part_doc = $model->new_partial_doc(
        uid            => $uid,
        partial_source => \%source
    );

Creates an instance of a partial doc (ie an object which contains only some of
the values stored in Elasticsearch). These partial docs are useful when
your objects are large, and you need to display search results which
require only a few attributes, instead of the whole object.

Attempting to save a partial doc will cause an error to be thrown.

You shouldn't need to call this method yourself.

=head3 bulk()

Returns a new instance of L<Elastic::Model::Bulk> for fast indexing
of multiple docs in batches.

    $bulk = $model->bulk(
        size        => 1000,
        on_conflict => sub {...},
        on_error    => sub {...},
        on_success  => sub {...}
    );

=head2 Miscellaneous

=head3 namespaces

    \%namespaces = $model->namespaces;

A hashref whose keys are the namespace names, and whose values are the
corresponding L<Elastic::Model::Namespace> instances.

=head3 namespace_for_domain()

    $namespace = $model->namespace_for_domain($domain_name)

Returns the L<Elastic::Model::Namespace> object which corresponds to the
C<$domain_name>.  If the index (or alias) name is not yet known to the
C<$model>, it will update the known domain list from the namespace objects.

=head3 all_live_indices()

    @indices = $model->all_live_indices();

Queries Elasticsearch to find all existing indices related to all namespaces
known to the model.

=head3 es

    $es = $model->es

Returns the L<Search::Elasticsearch> instance that was passed to L</"new()">.

=head3 store

    $store = $model->store

Returns the L<Elastic::Model::Store> instance.

=head2 Deflation, Inflation And Mapping

=head3 typemap

    $typemap_class = $model->typemap;

Elastic::Model uses L<Elastic::Model::TypeMap::Default> (after
L<wrapping|/wrap_class()> it) to figure out how
to deflate and inflate your objects, and how to configure (map) them in
Elasticsearch.

You can specify your own type-map class in your model configuration with
L<has_typemap|Elastic::Model/Custom TypeMap>. See
L<Elastic::Model::TypeMap::Base> for instructions on how to define
your own type-map classes.

=head3 deflator_for_class()

    $deflator = $model->deflator_for_class($class);

Returns a code-ref that knows how to deflate a class which does
L<Elastic::Model::Role::Doc>, and caches the deflator in L</"deflators">.

=head3 deflate_object()

    $hash = $model->deflate_object($object);

Uses the deflator returned by L</"deflator_for_class()"> to deflate
an object which does L<Elastic::Model::Role::Doc> into a hash ref
suitable for conversion to JSON.

=head3 deflators

    $deflators = $model->deflators

A hashref which caches all of the deflators which have been generated by
L</"deflator_for_class()">.

=head3 inflator_for_class()

    $inflator = $model->inflator_for_class($class);

Returns a code-ref that knows how to inflate a plain hashref into the correct
attribute values for a class which does L<Elastic::Model::Role::Doc>,
and caches the inflator in L</"inflators">.

=head3 inflate_object()

    $object = $model->inflate_object($object,$hash);

Uses the inflator returned by L</"inflator_for_class()"> to inflate
the attribute values of C<$object> from the value stored in C<$hash>.

=head3 inflators

    $inflators = $model->inflators

A hashref which caches all of the inflators which have been generated by
L</"inflator_for_class()">.

=head3 map_class()

    $mapping = $model->map_class($class);

Returns the type mapping / schema for a class which does
L<Elastic::Model::Role::Doc>, suitable for passing to Elasticsearch.

=head2 Scoping

Also see L</"new_scope()"> and L<Elastic::Model::Scope>.

=head3 current_scope()

    $scope = $model->current_scope($scope);

Read/write accessor for the current scope. Throws an exception if no scope
is currently set.

=head3 detach_scope()

    $model->detach_scope($scope);

Removes the passed in C<$scope> if it is the current scope. Replaces
the current scope with its parent scope, if there is one. L</"detach_scope()">
is called automatically when a scope goes out of scope:

    {
        my $scope = $model->new_scope;
        # do work
    }
    # current scope is removed

=head3 has_current_scope()

    $bool = $model->has_current_scope

Returns a true or false value signalling whether a L</"current_scope()">
exists.

=head3 clear_current_scope()

    $model->clear_current_scope

Clears the L</"current_scope()">

=head2 Core classes

The following core classes are used internally by Elasticsearch, after
being wrapped by L</wrap_class()>, which pins the new anonymous class
to the current C<$model> instance. An instance of the wrapped class
can be created with, eg:

    $domain = $model->domain_class->new(%args);

If you would like to override any of the core classes, then you can specify
them in your model setup using
L<override_classes|Elastic::Model/Overriding Core Classes>.

=head3 Default core classes:

=over

=item *

C<domain_class> C<--------------> L<Elastic::Model::Domain>

=item *

C<store_class> C<---------------> L<Elastic::Model::Store>

=item *

C<view_class> C<----------------> L<Elastic::Model::View>

=item *

C<scope_class> C<---------------> L<Elastic::Model::Scope>

=item *

C<results_class> C<-------------> L<Elastic::Model::Results>

=item *

C<cached_results_class> C<------> L<Elastic::Model::Results::Cached>

=item *

C<scrolled_results_class> C<----> L<Elastic::Model::Results::Scrolled>

=item *

C<result_class> C<--------------> L<Elastic::Model::Result>

=back

=head3 wrap_class()

    $wrapped_class = $model->wrap_class($class)

Wraps a class in an anonymous class and adds two methods: C<model()> (which
returns the current C<$model> instance, and C<original_class())>, which
returns the name of the wrapped class:

    $model = $wrapped_class->model
    $class = $wrapped_class->original_class;

=head3 wrap_doc_class()

Like L</"wrap_class()">, but specifically for classes which do
L<Elastic::Model::Role::Doc>.

=head3 doc_class_wrappers

    $wrapped_classes = $model->doc_class_wrappers

A hashref of all wrapped doc classes (ie those classes which do
L<Elastic::Model::Role::Doc>). The keys are the original class names, and
the values are the wrapped class names.

=head3 class_for()

    $wrapped_class = $model->class_for($class);

Returns the name of the wrapped class which corresponds to C<$class>.

=head3 knows_class()

    $bool = $model->knows_class($class);

Returns a true or false value to signal whether doc C<$class> has been wrapped.

=head1 AUTHOR

Clinton Gormley <drtech@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Clinton Gormley.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: The role applied to your Model

