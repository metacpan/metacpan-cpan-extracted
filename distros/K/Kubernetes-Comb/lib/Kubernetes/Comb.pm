package Kubernetes::Comb;
# ABSTRACT: A self-contained micro collection of Kubernetes parts as a live Perl instance
our $VERSION = '0.001';

use Moo;

use Carp qw( croak );
use Digest::SHA qw( sha256_hex );
use Future;
use Future::Utils qw( fmap_void );
use IO::K8s;
use JSON::MaybeXS qw( JSON is_bool );
use Module::Runtime qw( use_module use_package_optimistically );
use POSIX qw( strftime );
use Scalar::Util qw( blessed );
use Socket qw( AF_INET AF_INET6 inet_ntop inet_pton );
use Types::Common::Numeric qw( PositiveInt );
use Types::Standard qw( ArrayRef CodeRef ConsumerOf HashRef InstanceOf Maybe Object Str );
use Kubernetes::Comb::CRD;
use Kubernetes::Comb::CRD::Comb;
use Kubernetes::Comb::Client::Sync;
use Kubernetes::Comb::Endpoint;
use namespace::autoclean;



# group/Kind of the workloads, each with the paths below the object where it
# keeps the templates of what it creates. The Comb labels go there too, so
# the Pods (and a CronJob's Jobs) carry them. [] would be the object itself,
# which is always labelled; a bare Pod has nothing else.
my %WORKLOAD_TEMPLATES = (
  '/Pod'                   => [],
  '/ReplicationController' => [ [qw( spec template )] ],
  'apps/Deployment'        => [ [qw( spec template )] ],
  'apps/StatefulSet'       => [ [qw( spec template )] ],
  'apps/DaemonSet'         => [ [qw( spec template )] ],
  'apps/ReplicaSet'        => [ [qw( spec template )] ],
  'batch/Job'              => [ [qw( spec template )] ],
  'batch/CronJob'          => [ [qw( spec jobTemplate )], [qw( spec jobTemplate spec template )] ]
);

# Workloads that report ready replicas against spec.replicas.
my %REPLICATED = map { $_ => 1 } qw(
  /ReplicationController apps/Deployment apps/StatefulSet apps/ReplicaSet
);

# What L</stop> brings to rest, with the spec field that says so.
my %STOPPABLE = (
  'apps/Deployment'  => 'replicas',
  'apps/StatefulSet' => 'replicas',
  'batch/CronJob'    => 'suspend'
);

# What L</restart> rolls through its Pod template annotation.
my %RESTARTABLE = map { $_ => 1 } qw( apps/Deployment apps/StatefulSet apps/DaemonSet );

# Container waiting reasons that do not go away by waiting.
my %FAILURE_REASONS = map { $_ => 1 } qw(
  CrashLoopBackOff ImagePullBackOff ErrImagePull ErrImageNeverPull InvalidImageName
  CreateContainerConfigError CreateContainerError RunContainerError
);

my %ENDPOINT_KEYS = map { $_ => 1 } qw( name port protocol service cluster external );

####
#### Attributes
####

has k8s => (
  is  => 'lazy',
  isa => ConsumerOf['Kubernetes::Comb::Role::Client']
);

sub _build_k8s { Kubernetes::Comb::Client::Sync->new }


has resolver => ( is => 'ro', isa => CodeRef, predicate => 1 );


# init_arg upstream, but no `upstream` reader: a Comb class may define a plain
# `upstream` method (SPEC §5, source 3), and whether it does must stay visible
# to can().
has _upstream => (
  is        => 'ro',
  isa       => Maybe[ CodeRef | HashRef | ArrayRef | Object ],
  init_arg  => 'upstream',
  predicate => 1
);


has crd => (
  is        => 'rwp',
  isa       => InstanceOf['Kubernetes::Comb::CRD::Comb'],
  predicate => 1
);


has crd_class => ( is => 'lazy', isa => Str, predicate => '_has_crd_class' );

sub _build_crd_class {
  my ( $self ) = @_;
  return $self->has_crd ? ref $self->crd : 'Kubernetes::Comb::CRD::Comb';
}


has namespace => ( is => 'lazy', isa => Str );

sub _build_namespace {
  my ( $self ) = @_;
  my $meta = $self->has_crd ? $self->crd->metadata : undef;
  my $namespace = $meta ? $meta->namespace : undef;
  croak ref($self).' has no namespace: pass namespace, or a crd with metadata.namespace'
    unless defined $namespace && length $namespace;
  return $namespace;
}


has config => ( is => 'lazy', isa => HashRef );

sub _build_config {
  my ( $self ) = @_;
  my $spec = $self->has_crd ? $self->crd->spec : undef;
  return $spec && $spec->config ? { %{ $spec->config } } : {};
}


has label_prefix => ( is => 'ro', isa => Str, default => 'comb.internal/' );


has managed_by => ( is => 'ro', isa => Str, default => 'kubernetes-comb' );


has max_upstream_depth => ( is => 'ro', isa => PositiveInt, default => 16 );


has cluster_domain => ( is => 'ro', isa => Str, default => 'cluster.local' );


has io_k8s => ( is => 'lazy', isa => InstanceOf['IO::K8s'] );

sub _build_io_k8s {
  my ( $self ) = @_;
  return IO::K8s->new( with => [ Kubernetes::Comb::CRD->new( crd_class => $self->crd_class ) ] );
}


has stub_of => (
  is        => 'ro',
  isa       => InstanceOf['Kubernetes::Comb'],
  predicate => 'is_stub'
);


# The recorded status without a CR (with one it is crd->status).
has _memory_status => (
  is       => 'rw',
  isa      => Maybe[ InstanceOf['Kubernetes::Comb::CRD::CombStatus'] ],
  init_arg => undef
);

# Canonical, so the same manifest always encodes to the same bytes.
has _digest_encoder => ( is => 'lazy', init_arg => undef );

sub _build__digest_encoder { JSON->new->utf8->canonical }

sub BUILD {
  my ( $self, $args ) = @_;
  croak ref($self).': crd is a '.ref( $self->crd ).', not a '.$self->crd_class
    if $self->has_crd && $self->_has_crd_class && !$self->crd->isa( $self->crd_class );
  $self->_check_name;
  my $original = $self->is_stub ? $self->stub_of : $self->_original_by_name($args);
  $self->_check_stub_contract($original) if $original;
}

# The name is a label value on every resource of the Comb. A Comb that has
# no name yet fails its operations instead, not its construction.
sub _check_name {
  my ( $self ) = @_;
  my ( $name ) = eval { $self->name };
  return unless defined $name;
  croak ref($self).": the name '".$name."' cannot be a label value, and it is one on every resource"
    .' (at most 63 characters: letters, digits, -, _ and ., alphanumeric at both ends)'
    unless length $name <= 63 && $name =~ /\A[A-Za-z0-9](?:[-A-Za-z0-9_.]*[A-Za-z0-9])?\z/;
}

# Foo::Stub that is a Foo stands in for a Foo, however it was selected: the
# Foo built from the same arguments, to check the contract against.
sub _original_by_name {
  my ( $self, $args ) = @_;
  my ( $original ) = ref($self) =~ /\A(.+)::Stub\z/;
  return unless defined $original && $self->isa($original) && $original->isa(__PACKAGE__);
  return $original->new(%$args);
}

sub _check_stub_contract {
  my ( $self, $original ) = @_;
  my %own = map { $_ => 1 } $self->_endpoint_names;
  my @missing = grep { !$own{$_} } $original->_endpoint_names;
  croak ref($self).' does not keep the contract of '.ref($original)
    .': missing endpoint(s) '.join( ', ', @missing ) if @missing;
}

####
#### Contract
####

sub name {
  my ( $self ) = @_;
  my $meta = $self->has_crd ? $self->crd->metadata : undef;
  return $meta->name if $meta && defined $meta->name && length $meta->name;
  croak ref($self).' has no name: override name, or build it from a Comb custom resource';
}


sub depends_on {
  my ( $self ) = @_;
  my $spec = $self->has_crd ? $self->crd->spec : undef;
  return $spec ? @{ $spec->dependsOn // [] } : ();
}


sub endpoints { return }


sub manifests { return }


sub check { return }


sub optional { 0 }


sub bridge_manifests {
  my ( $self, @endpoints ) = @_;
  my %declared = map { ( $_->{name} => $_ ) } $self->_declared_endpoints;
  my ( @services, %of );
  for my $endpoint (@endpoints) {
    my $declared = $declared{ $endpoint->name } // {};
    my $service = $declared->{service} // $self->name;
    push @services, $service unless $of{$service};
    push @{ $of{$service} }, $endpoint;
  }
  my ( @manifests, @problems );
  for my $service (@services) {
    my ( $manifests, $problems ) = $self->_bridge_service( $service, @{ $of{$service} } );
    push @manifests, @$manifests;
    push @problems, @$problems;
  }
  return @problems ? Future->fail( join( '; ', @problems ), 'bridge' ) : Future->done(@manifests);
}


sub stub_class {
  my ( $self ) = @_;
  my $stub = ( ref $self || $self ).'::Stub';
  use_package_optimistically($stub) unless $stub->can('new');
  return $stub->can('new') ? $stub : undef;
}


sub endpoint_class { 'Kubernetes::Comb::Endpoint' }


####
#### Construction from the CR
####

sub from_crd {
  my ( $self, $crd, %opts ) = @_;
  my $base = ref $self || $self;
  croak $base.'->from_crd needs a Comb custom resource object'
    unless blessed $crd && $crd->isa('Kubernetes::Comb::CRD::Comb');
  croak $base.'->from_crd: the custom resource has no spec.class'
    unless $crd->spec && $crd->spec->class;
  my $stub = delete $opts{stub};
  croak $base.'->from_crd: stub must be a coderef' if defined $stub && ref $stub ne 'CODE';

  my $class = $self->_load_comb_class( $crd->spec->class, $base );
  my $comb  = $class->new( %opts, crd => $crd );
  return $comb unless $stub && $stub->($comb);

  my $stub_class = $comb->stub_class;
  croak $base.'->from_crd: a stub was asked for '.$comb->name.', but '.$class.' has no stub class'
    unless defined $stub_class;
  return $self->_load_comb_class( $stub_class, __PACKAGE__ )
    ->new( %opts, crd => $crd, stub_of => $comb );
}


sub _load_comb_class {
  my ( $self, $class, $base ) = @_;
  use_module($class) unless $class->can('new');
  croak( ( ref $self || $self ).'->from_crd: '.$class.' is not a '.$base )
    unless $class->isa($base);
  return $class;
}

####
#### Labels
####

sub comb_label { shift->label_prefix.'comb' }


sub comb_namespace_label { shift->label_prefix.'comb-namespace' }


sub comb_labels {
  my ( $self ) = @_;
  return {
    $self->comb_label              => $self->name,
    $self->comb_namespace_label    => $self->namespace,
    'app.kubernetes.io/managed-by' => $self->managed_by
  };
}


sub label_selector {
  my ( $self ) = @_;
  return $self->comb_label.'='.$self->name.','.$self->comb_namespace_label.'='.$self->namespace;
}


sub restart_annotation { shift->label_prefix.'restartedAt' }


sub applied_digest_annotation { shift->label_prefix.'applied-digest' }


####
#### Lifecycle
####

sub reconcile {
  my ( $self ) = @_;
  my $r = { previous => $self->recorded_status, conditions => {} };
  return Future->call( sub { $self->_reconcile_steps($r) } )
    ->else( sub { $self->_finish( $r, Error => ReconcileFailed => $self->_message( $_[0] ) ) } )
    ->then( sub { $self->_publish_endpoints($r) } )
    ->then( sub { $self->_record($r) } )
    ->else( sub { Future->done( $self->_last_resort( $_[0] ) ) } );
}


sub deploy {
  my ( $self ) = @_;
  return Future->call( sub {
    $self->_render->then( sub { $self->_apply(@_) } );
  } );
}


sub status {
  my ( $self ) = @_;
  return Future->call( sub {
    $self->_resolve_upstream->then( sub {
      my ( $upstream ) = @_;
      return $upstream ? $self->_borrowed_status($upstream) : $self->_local_status;
    } );
  } );
}


sub healthy {
  my ( $self ) = @_;
  return $self->status->then( sub { Future->done( $_[0]{healthy} ) } );
}


sub logs {
  my ( $self, %args ) = @_;
  my $lines = $args{lines} // 100;
  return Future->call( sub {
    $self->_pods->then( sub {
      my @streams = map { $self->_log_streams($_) } @_;
      return Future->needs_all( map { $self->_log_text( $_, $lines ) } @streams )->then( sub {
        my @texts = @_;
        my $headers = @streams > 1 || grep { $_->{previous} } @streams;
        return Future->done( join "\n", map {
          ( $headers ? '==> '.$streams[$_]{label}.' <=='."\n" : '' ).$texts[$_]
        } 0 .. $#streams );
      } );
    } );
  } );
}


sub restart {
  my ( $self ) = @_;
  return Future->call( sub {
    my $patch = {
      spec => { template => { metadata => { annotations => {
        $self->restart_annotation => $self->_now
      } } } }
    };
    my $roll = sub { $self->k8s->patch( $_[0], patch => $patch, type => 'merge' ) };
    return $self->_each_workload(
      [ 'apps/v1/Deployment'  => $roll ],
      [ 'apps/v1/StatefulSet' => $roll ],
      [ 'apps/v1/DaemonSet'   => $roll ],
      [ 'batch/v1/Job'        => $self->_delete_job ]
    );
  } );
}


sub stop {
  my ( $self ) = @_;
  return Future->call( sub {
    my $scale = sub { $self->k8s->patch( $_[0], patch => { spec => { replicas => 0 } }, type => 'merge' ) };
    return $self->_each_workload(
      [ 'apps/v1/Deployment'  => $scale ],
      [ 'apps/v1/StatefulSet' => $scale ],
      [ 'batch/v1/CronJob'    => sub {
        $self->k8s->patch( $_[0], patch => { spec => { suspend => JSON->true } }, type => 'merge' )
      } ],
      [ 'batch/v1/Job' => $self->_delete_job ]
    );
  } );
}


sub describe {
  my ( $self ) = @_;
  return Future->call( sub {
    my $recorded = $self->recorded_status;
    my %describe = (
      name       => $self->name,
      class      => ref $self,
      namespace  => $self->namespace,
      depends_on => [ $self->depends_on ],
      ( $self->is_stub ? ( stub_of => ref $self->stub_of ) : () ),
      ( $recorded ? ( recorded => $recorded->TO_JSON ) : () )
    );
    return $self->_resolve_endpoints->then( sub {
      $describe{endpoints} = [ map { $_->to_crd->TO_JSON } @_ ];
      return $self->status;
    } )->then( sub {
      $describe{status} = $_[0];
      return Future->done( \%describe );
    } );
  } );
}


sub endpoint {
  my ( $self, $name ) = @_;
  return Future->call( sub {
    croak ref($self).'->endpoint needs a name' unless defined $name;
    return $self->_resolve_endpoints->then( sub {
      my ( $endpoint ) = grep { $_->name eq $name } @_;
      return Future->done($endpoint) if $endpoint;
      return Future->fail( ref($self).'->endpoint: '.$self->name.' has no endpoint '.$name
        .' (it has: '.( join( ', ', map { $_->name } @_ ) || 'none' ).')' );
    } );
  } );
}


sub recorded_status {
  my ( $self ) = @_;
  return $self->has_crd ? $self->crd->status : $self->_memory_status;
}


####
#### Internals
####

# A contract method whose result may be a list or one Future of it, as a
# Future; whatever it dies with becomes the failure.
sub _hook {
  my ( $self, $method, @args ) = @_;
  return Future->call( sub {
    my @result = $self->$method(@args);
    return @result == 1 && blessed $result[0] && $result[0]->isa('Future')
      ? $result[0]
      : Future->done(@result);
  } );
}

# Fails with category manifests, so a broken manifest stays apart from a
# failing request further down the chain.
sub _render {
  my ( $self ) = @_;
  return $self->_hook('manifests')
    ->then( sub { Future->done( $self->_items(@_) ) } )
    ->else( sub { Future->fail( $_[0], 'manifests' ) } );
}

sub _items {
  my ( $self, @manifests ) = @_;
  return map { $self->_item($_) } @manifests;
}

# One manifest, ready to apply -- labelled, namespace set, a copy of what the
# class returned -- plus what the Comb needs to know about it.
sub _item {
  my ( $self, $manifest ) = @_;
  my $class = blessed $manifest;
  my $data = $class ? $manifest->TO_JSON : $manifest;
  croak ref($self).': a manifest is an IO::K8s object or a hashref, got '
    .( ref $manifest || 'a plain scalar' ) unless ref $data eq 'HASH';
  my $kind = $data->{kind};
  croak ref($self).': a manifest has no kind' unless defined $kind && length $kind;
  my $name = ref $data->{metadata} eq 'HASH' ? $data->{metadata}{name} : undef;
  croak ref($self).': manifest '.$kind.' has no metadata.name' unless defined $name && length $name;

  my $labels = $self->comb_labels;
  my $object = $self->_merged_meta( $data, [], labels => $labels );
  $object->{apiVersion} //= $self->_api_version_of($kind);
  my ( $group ) = $object->{apiVersion} =~ m{\A(.+)/[^/]+\z};
  $group //= '';
  my $templates = $WORKLOAD_TEMPLATES{ $group.'/'.$kind };
  $object = $self->_merged_meta( $object, $_, labels => $labels ) for @{ $templates // [] };
  my $namespace = $object->{metadata}{namespace};
  $object->{metadata}{namespace} = $namespace = $self->namespace
    if !( defined $namespace && length $namespace ) && $self->_namespaced( $class, $object );
  # Of the manifest as it stands here: what the class rendered plus what the
  # Comb adds to every one. The annotation itself comes after it, and so does
  # what deploy carries over from the live object (_restart_kept).
  my $digest = $self->_digest_of( $object, $kind.' '.$name );
  $object = $self->_merged_meta( $object, [], annotations => { $self->applied_digest_annotation => $digest } );

  return {
    manifest   => $class ? $class->FROM_HASH($object) : $object,
    data       => $object,
    digest     => $digest,
    class      => $class,
    apiVersion => $object->{apiVersion},
    kind       => $kind,
    group      => $group,
    name       => $name,
    namespace  => $namespace,
    resource   => $class && $class ne 'IO::K8s::Unstructured'
      ? '+'.$class
      : $object->{apiVersion}.'/'.$kind,
    workload   => $templates ? 1 : 0
  };
}

# A copy of $node with $values merged into metadata.$field (labels,
# annotations) at $path below it, copying only what it changes. A path that
# does not exist is left alone.
sub _merged_meta {
  my ( $self, $node, $path, $field, $values ) = @_;
  my %copy = %$node;
  if ( my ( $key, @rest ) = @$path ) {
    $copy{$key} = $self->_merged_meta( $copy{$key}, \@rest, $field, $values ) if ref $copy{$key} eq 'HASH';
    return \%copy;
  }
  my %meta = ref $copy{metadata} eq 'HASH' ? %{ $copy{metadata} } : ();
  $meta{$field} = { %{ $meta{$field} // {} }, %$values };
  $copy{metadata} = \%meta;
  return \%copy;
}

# The digest of a manifest, as the annotation holds it. A digest the
# manifest brings along -- rendered from a live object, say -- is left out.
sub _digest_of {
  my ( $self, $object, $what ) = @_;
  my $plain = $self->_digestable( $object, $what );
  my $meta = $plain->{metadata};
  if ( ref $meta eq 'HASH' && ref $meta->{annotations} eq 'HASH' ) {
    delete $meta->{annotations}{ $self->applied_digest_annotation };
    delete $meta->{annotations} unless %{ $meta->{annotations} };
  }
  return 'sha256:'.sha256_hex( $self->_digest_encoder->encode($plain) );
}

# A copy of the value that encodes the same whatever Perl did to its
# scalars: a number that was used as a string encodes as a string from then
# on, and the other way round, and the manifest of a class is read more than
# once. So every leaf is a string, but for undef and the JSON booleans (\1
# and \0 too). Dies on what no manifest holds.
sub _digestable {
  my ( $self, $value, $what ) = @_;
  return $value unless defined $value;
  my $ref = ref $value;
  return ''.$value unless $ref;
  if ( blessed $value ) {
    return $value ? JSON->true : JSON->false if is_bool($value);
    croak ref($self).': manifest '.$what.' cannot be digested: it holds a '.$ref.' object'
      unless $value->can('TO_JSON');
    return $self->_digestable( $value->TO_JSON, $what );
  }
  return { map { ( $_ => $self->_digestable( $value->{$_}, $what ) ) } keys %$value } if $ref eq 'HASH';
  return [ map { $self->_digestable( $_, $what ) } @$value ] if $ref eq 'ARRAY';
  return $$value ? JSON->true : JSON->false
    if $ref eq 'SCALAR' && defined $$value && $$value =~ /\A[01]\z/;
  croak ref($self).': manifest '.$what.' cannot be digested: it holds a '.$ref.' reference';
}

# The spec the item renders, {} when it has none.
sub _rendered_spec {
  my ( $self, $item ) = @_;
  my $spec = $item->{data}{spec};
  return ref $spec eq 'HASH' ? $spec : {};
}

sub _api_version_of {
  my ( $self, $kind ) = @_;
  my $io = $self->io_k8s;
  my $class = eval { my $c = $io->expand_class($kind); $io->load_class($c); $c };
  croak ref($self).': manifest '.$kind.' has no apiVersion, and '.$kind.' is no Kind IO::K8s knows'
    unless $class && $class->can('api_version');
  return $class->api_version;
}

# A Kind io_k8s does not know counts as namespaced: the parts of a Comb
# nearly always are, and the API server drops the namespace of a
# cluster-scoped object anyway.
sub _namespaced {
  my ( $self, $class, $object ) = @_;
  unless ( $class && $class ne 'IO::K8s::Unstructured' ) {
    $class = $self->io_k8s->expand_class( $object->{kind}, $object->{apiVersion} );
    return 1 unless defined $class;
    $self->io_k8s->load_class($class);
  }
  return $class->does('IO::K8s::Role::Namespaced') ? 1 : 0;
}

# Sequentially, so a Namespace or a CRD comes before what needs it.
sub _apply {
  my ( $self, @items ) = @_;
  my @applied;
  return $self->_keep_restarts(@items)->else( sub {
    Future->fail( 'reading the live workloads failed: '.$self->_message( $_[0] ), deploy => { applied => [] } );
  } )->then( sub {
    my @kept = @_;
    return ( fmap_void {
      my ( $item ) = @_;
      $self->k8s->ensure( $item->{manifest} )->then(
        sub { push @applied, $_[0]; Future->done },
        sub {
          Future->fail(
            'ensure '.$item->{kind}.' '.$item->{name}.': '.$_[0],
            deploy => { applied => [@applied], failed => $item->{manifest} }
          );
        }
      );
    } foreach => \@kept, concurrent => 1 )->then( sub { Future->done(@applied) } );
  } );
}

# Future of the items, each Deployment, StatefulSet and DaemonSet with the
# restart annotation of its live Pod template: ensure replaces the object,
# and without it the Pods would roll once more -- or a rolling restart would
# be undone. Reads the live objects the items do not have yet.
sub _keep_restarts {
  my ( $self, @items ) = @_;
  return Future->call( sub {
    my @unread = grep { $RESTARTABLE{ $_->{group}.'/'.$_->{kind} } && !exists $_->{live} } @items;
    return ( @unread ? $self->_fetch_live(@unread) : Future->done )->then( sub {
      Future->done( map { $self->_restart_kept($_) } @items );
    } );
  } );
}

sub _restart_kept {
  my ( $self, $item ) = @_;
  return $item unless $RESTARTABLE{ $item->{group}.'/'.$item->{kind} } && $item->{live};
  my $template = $item->{live}->TO_JSON->{spec}{template};
  my $meta = ref $template eq 'HASH' ? $template->{metadata} : undef;
  my $at = ref $meta eq 'HASH' && ref $meta->{annotations} eq 'HASH'
    ? $meta->{annotations}{ $self->restart_annotation }
    : undef;
  return $item unless defined $at;
  my $data = $self->_merged_meta( $item->{data}, [qw( spec template )],
    annotations => { $self->restart_annotation => $at } );
  return { %$item, data => $data, manifest => $item->{class} ? $item->{class}->FROM_HASH($data) : $data };
}

# What status says of a Comb that runs its own resources.
sub _local_status {
  my ( $self ) = @_;
  return Future->call( sub {
    $self->_render->then( sub { $self->_observe_local(@_) } );
  } );
}

# Future of what status says of the rendered @items; each item gets its live
# object (or undef) in $item->{live}.
sub _observe_local {
  my ( $self, @items ) = @_;
  return Future->call( sub {
    return Future->done( $self->_status_of( \@items, [] ) ) unless @items;
    return $self->_fetch_live(@items)->then( sub {
      return Future->done( $self->_status_of( \@items, [] ) )
        unless grep { $_->{workload} && $_->{live} } @items;
      return $self->_pods->then( sub { Future->done( $self->_status_of( \@items, [@_] ) ) } );
    } );
  } );
}

# What status says of a Comb that borrows from $upstream.
sub _borrowed_status {
  my ( $self, $upstream ) = @_;
  return $self->_observe_upstream($upstream)->then( sub {
    my ( $o ) = @_;
    my %upstream = ( upstream => $self->_upstream_record($o) );
    if ( my $stop = $o->{stop} ) {
      my ( $phase, $reason, $message ) = @$stop;
      return Future->done( {
        %{ $self->_verdict( $phase, [ { severity => 'error', reason => $reason, message => $message } ], [] ) },
        %upstream
      } );
    }
    my @items = @{ $o->{items} };
    return $self->_fetch_live(@items)->then( sub {
      my @problems = map { +{
        severity => 'pending',
        reason   => 'ResourcesMissing',
        message  => $_->{kind}.' '.$_->{name}.' is missing'
      } } grep { !$_->{live} } @items;
      my ( $phase, $reason, $message ) = $self->_borrowed_verdict($o);
      push @problems, { severity => 'pending', reason => $reason, message => $message } if $phase ne 'Running';
      $phase = !@problems                               ? 'Running'
             : @items && !grep( { $_->{live} } @items ) ? 'NotDeployed'
             :                                            'Pending';
      return Future->done( { %{ $self->_verdict( $phase, \@problems, [] ) }, %upstream } );
    } );
  } );
}

# Puts the live object (or undef) of every item into $item->{live}: one list
# per resource and namespace, by label, so a missing object is an empty
# answer rather than an error to tell apart from others.
sub _fetch_live {
  my ( $self, @items ) = @_;
  my %groups;
  push @{ $groups{ $_->{resource} }{ $_->{namespace} // '' } }, $_ for @items;
  return Future->needs_all( map {
    my $resource = $_;
    map {
      my ( $namespace, $members ) = ( $_, $groups{$resource}{$_} );
      # By the name label alone: a same-named Comb of another namespace that
      # renders the same resource may have applied it last, and requiring
      # the namespace label here would make both deploy it every step.
      $self->k8s->list( $resource,
        ( length $namespace ? ( namespace => $namespace ) : () ),
        labelSelector => $self->comb_label.'='.$self->name
      )->then( sub {
        my %live = map { ( $_->metadata->name => $_ ) } @{ $_[0]->items // [] };
        $_->{live} = $live{ $_->{name} } for @$members;
        return Future->done;
      } );
    } sort keys %{ $groups{$resource} };
  } sort keys %groups );
}

sub _pods {
  my ( $self ) = @_;
  return $self->k8s->list( 'v1/Pod',
    namespace     => $self->namespace,
    labelSelector => $self->label_selector
  )->then( sub {
    return Future->done( sort { $a->metadata->name cmp $b->metadata->name } @{ $_[0]->items // [] } );
  } );
}

sub _status_of {
  my ( $self, $items, $pods ) = @_;
  my ( @pods, @problems );
  for my $pod (@$pods) {
    my ( $state, $problem ) = $self->_pod_state($pod);
    push @pods, $state;
    push @problems, $problem if $problem;
  }
  return $self->_verdict( Running => [], \@pods ) unless @$items;
  return $self->_verdict( NotDeployed => [ {
    severity => 'pending', reason => 'NotDeployed', message => 'not deployed'
  } ], \@pods ) unless grep { $_->{live} } @$items;
  return $self->_verdict( Stopped => [ {
    severity => 'pending', reason => 'Stopped', message => 'stopped'
  } ], \@pods ) if $self->_stopped($items);

  unshift @problems, map { +{
    severity => 'pending',
    reason   => 'ResourcesMissing',
    message  => $_->{kind}.' '.$_->{name}.' is missing'
  } } grep { !$_->{live} } @$items;
  push @problems, map { $self->_workload_problem($_) } grep { $_->{workload} && $_->{live} } @$items;

  my $phase = ( grep { $_->{severity} eq 'error' } @problems ) ? 'Error'
            : @problems                                        ? 'Pending'
            :                                                    'Running';
  return $self->_verdict( $phase, \@problems, \@pods );
}

sub _verdict {
  my ( $self, $phase, $problems, $pods ) = @_;
  my ( $first ) = ( ( grep { $_->{severity} eq 'error' } @$problems ), @$problems );
  return {
    phase   => $phase,
    healthy => $phase eq 'Running' ? JSON->true : JSON->false,
    ( $first ? (
      reason  => $first->{reason},
      message => join( '; ', map { $_->{message} } @$problems )
    ) : () ),
    pods    => $pods
  };
}

# What L</stop> leaves: every Deployment/StatefulSet at 0, every CronJob
# suspended -- at least one of them against its manifest. The workloads stop
# does not bring to rest (a DaemonSet, a ReplicaSet, a bare Pod) do not
# count either way, its Jobs it deletes. A manifest that says 0 or
# suspended itself is at rest as rendered, not stopped.
sub _stopped {
  my ( $self, $items ) = @_;
  my $against = 0;
  for my $item ( grep { $_->{live} } @$items ) {
    my $field = $STOPPABLE{ $item->{group}.'/'.$item->{kind} } or next;
    my $live = $item->{live}->TO_JSON->{spec} // {};
    my $want = $self->_rendered_spec($item);
    if ( $field eq 'suspend' ) {
      return 0 unless $live->{suspend};
      $against++ unless $want->{suspend};
    }
    else {
      return 0 if ( $live->{replicas} // 1 ) != 0;
      $against++ if ( $want->{replicas} // 1 ) != 0;
    }
  }
  return $against ? 1 : 0;
}

sub _workload_problem {
  my ( $self, $item ) = @_;
  my $live   = $item->{live}->TO_JSON;
  my $spec   = $live->{spec}   // {};
  my $status = $live->{status} // {};
  my $what   = $item->{kind}.' '.$item->{name};
  my $key    = $item->{group}.'/'.$item->{kind};

  if ( $key eq 'batch/Job' ) {
    my %true = map { ( $_->{type} => $_ ) }
      grep { ( $_->{status} // '' ) eq 'True' } @{ $status->{conditions} // [] };
    if ( my $failed = $true{Failed} ) {
      return {
        severity => 'error',
        reason   => $failed->{reason} // 'JobFailed',
        message  => $what.' failed'.( $failed->{message} ? ': '.$failed->{message} : '' )
      };
    }
    return if $true{Complete} || ( $status->{succeeded} // 0 ) >= ( $spec->{completions} // 1 );
    return { severity => 'pending', reason => 'JobNotComplete', message => $what.' has not completed' };
  }

  my ( $ready, $desired, $scaled_down );
  if ( $key eq 'apps/DaemonSet' ) {
    ( $ready, $desired ) = ( $status->{numberReady} // 0, $status->{desiredNumberScheduled} // 0 );
  }
  elsif ( $REPLICATED{$key} ) {
    # Scaled below what the manifest says -- deploy sets that, default 1 --
    # by stop or by hand is short of replicas; scaled beyond it (by hand, an
    # autoscaler), the scale counts.
    my $scaled = $spec->{replicas} // 1;
    my $wanted = $self->_rendered_spec($item)->{replicas} // 1;
    $scaled_down = $scaled < $wanted ? $scaled : undef;
    ( $ready, $desired ) = ( $status->{readyReplicas} // 0, $scaled < $wanted ? $wanted : $scaled );
  }
  else {
    return;   # a bare Pod speaks for itself, a CronJob has nothing to wait for
  }
  return if $ready >= $desired;
  return {
    severity => 'pending',
    reason   => 'ReplicasNotReady',
    message  => $what.': '.$ready.' of '.$desired.' ready'
      .( defined $scaled_down ? ' (scaled to '.$scaled_down.')' : '' )
  };
}

# The public view of a Pod, and the problem it is for the Comb, if any.
sub _pod_state {
  my ( $self, $pod ) = @_;
  my $data       = $pod->TO_JSON;
  my $status     = $data->{status} // {};
  my $phase      = $status->{phase} // 'Unknown';
  my @containers = @{ $status->{containerStatuses} // [] };
  my @all        = ( @{ $status->{initContainerStatuses} // [] }, @containers );
  my $restarts   = 0;
  $restarts += $_->{restartCount} // 0 for @all;
  my $ready = $phase eq 'Running' && @containers && !grep { !$_->{ready} } @containers;

  my %state = (
    name     => $data->{metadata}{name},
    phase    => $phase,
    ready    => $ready ? JSON->true : JSON->false,
    restarts => $restarts
  );
  return \%state if $phase eq 'Succeeded' || $ready;

  my ( $severity, $reason, $message );
  my ( $container ) = grep {
    $_->{state}{waiting} || ( $_->{state}{terminated} && ( $_->{state}{terminated}{exitCode} // 0 ) != 0 )
  } @all;
  my ( $unscheduled ) = grep {
    $_->{type} eq 'PodScheduled' && ( $_->{status} // '' ) eq 'False'
  } @{ $status->{conditions} // [] };

  if ( $phase eq 'Failed' ) {
    my $terminated = $container ? $container->{state}{terminated} : undef;
    $reason   = $status->{reason} // ( $terminated ? $terminated->{reason} : undef ) // 'Failed';
    $message  = $status->{message} // ( $terminated ? $self->_exit_message($terminated) : undef );
    $severity = @{ $data->{metadata}{ownerReferences} // [] } ? undef : 'error';
  }
  elsif ($unscheduled) {
    ( $severity, $reason, $message ) = ( 'pending', $unscheduled->{reason} // 'Unschedulable', $unscheduled->{message} );
  }
  elsif ( $container && ( my $waiting = $container->{state}{waiting} ) ) {
    $reason   = $waiting->{reason} // 'Waiting';
    $message  = $waiting->{message};
    $severity = $FAILURE_REASONS{$reason} ? 'error' : 'pending';
  }
  elsif ($container) {
    my $terminated = $container->{state}{terminated};
    ( $severity, $reason, $message ) = ( 'error', $terminated->{reason} // 'Error', $self->_exit_message($terminated) );
  }
  elsif ( $phase eq 'Unknown' ) {
    ( $severity, $reason, $message ) = ( 'error', $status->{reason} // 'Unknown', $status->{message} );
  }
  else {
    ( $severity, $reason ) = ( 'pending', $phase eq 'Pending' ? 'Pending' : 'ContainersNotReady' );
  }

  $state{reason}  = $reason;
  $state{message} = $message if defined $message;
  return \%state unless $severity;
  return ( \%state, {
    severity => $severity,
    reason   => $reason,
    message  => 'Pod '.$state{name}.': '.$reason
      .( defined $message && length $message ? ': '.$message : '' )
      .( $restarts ? ' ('.$restarts.' restarts)' : '' )
  } );
}

sub _exit_message {
  my ( $self, $terminated ) = @_;
  return 'exit code '.( $terminated->{exitCode} // '?' )
    .( $terminated->{message} ? ': '.$terminated->{message} : '' );
}

sub _log_streams {
  my ( $self, $pod ) = @_;
  my $data = $pod->TO_JSON;
  my $name = $data->{metadata}{name};
  my %status = map { ( $_->{name} => $_ ) } @{ $data->{status}{containerStatuses} // [] };
  my @containers = map { $_->{name} } @{ $data->{spec}{containers} // [] };
  return map {
    my $waiting  = $status{$_} && $status{$_}{state} ? $status{$_}{state}{waiting} : undef;
    my $previous = $waiting && ( $waiting->{reason} // '' ) eq 'CrashLoopBackOff' ? 1 : 0;
    +{
      pod       => $name,
      container => $_,
      previous  => $previous,
      label     => $name.( @containers > 1 ? '/'.$_ : '' ).( $previous ? ' (previous)' : '' )
    };
  } @containers;
}

sub _log_text {
  my ( $self, $stream, $lines ) = @_;
  return $self->k8s->log( 'v1/Pod', $stream->{pod},
    namespace => $self->namespace,
    container => $stream->{container},
    ( $stream->{previous} ? ( previous => 1 ) : () ),
    tailLines => $lines
  )->then(
    sub {
      my $text = $_[0] // '';
      $text .= "\n" if length $text && $text !~ /\n\z/;
      return Future->done($text);
    },
    sub { Future->done( '(no log: '.( $_[0] =~ s/\s+\z//r ).")\n" ) }
  );
}

# Lists each resource of the Comb by label, runs the action on every object
# found; Future of the list of what it touched, as Kind/name.
sub _each_workload {
  my ( $self, @actions ) = @_;
  return Future->needs_all( map {
    my ( $resource, $action ) = @$_;
    $self->k8s->list( $resource,
      namespace     => $self->namespace,
      labelSelector => $self->label_selector
    )->then( sub {
      my @objects = sort { $a->metadata->name cmp $b->metadata->name } @{ $_[0]->items // [] };
      return Future->needs_all( map {
        my $object = $_;
        $action->($object)->then( sub { Future->done( $object->kind.'/'.$object->metadata->name ) } );
      } @objects );
    } );
  } @actions );
}

# Background: without a propagationPolicy the API server orphans the Pods of
# a deleted batch/v1 Job.
sub _delete_job {
  my ( $self ) = @_;
  return sub { $self->k8s->delete( $_[0], propagationPolicy => 'Background' ) };
}

# The endpoints as they are reached now: the local ones, or with an active
# upstream the redirected ones -- failing with the reason when there are
# none.
sub _resolve_endpoints {
  my ( $self ) = @_;
  return Future->call( sub {
    $self->_resolve_upstream->then( sub {
      my ( $upstream ) = @_;
      return Future->done( $self->_local_endpoints ) unless $upstream;
      return $self->_observe_upstream($upstream)->then( sub {
        my ( $o ) = @_;
        return $o->{endpoints} ? Future->done( @{ $o->{endpoints} } ) : Future->fail( $o->{stop}[2] );
      } );
    } );
  } );
}

sub _local_endpoints {
  my ( $self ) = @_;
  return map { $self->_local_endpoint($_) } $self->_declared_endpoints;
}

sub _local_endpoint {
  my ( $self, $declared ) = @_;
  return $self->endpoint_class->new(
    name    => $declared->{name},
    port    => $declared->{port},
    ( defined $declared->{protocol} ? ( protocol => $declared->{protocol} ) : () ),
    cluster => $declared->{cluster}
      // ( $declared->{service} // $self->name ).'.'.$self->namespace.'.svc:'.$declared->{port},
    ( defined $declared->{external} ? ( external => $declared->{external} ) : () )
  );
}

sub _declared_endpoints {
  my ( $self ) = @_;
  my ( @declared, %seen );
  for my $endpoint ( $self->endpoints ) {
    my %declared;
    if ( blessed $endpoint && $endpoint->isa('Kubernetes::Comb::Endpoint') ) {
      %declared = (
        name     => $endpoint->name,
        port     => $endpoint->port,
        protocol => $endpoint->protocol,
        ( $endpoint->has_cluster  ? ( cluster  => $endpoint->cluster )  : () ),
        ( $endpoint->has_external ? ( external => $endpoint->external ) : () )
      );
    }
    elsif ( ref $endpoint eq 'HASH' ) {
      %declared = %$endpoint;
      my @unknown = sort grep { !$ENDPOINT_KEYS{$_} } keys %declared;
      croak ref($self).'->endpoints: unknown key(s) '.join( ', ', @unknown )
        .' (known: '.join( ', ', sort keys %ENDPOINT_KEYS ).')' if @unknown;
    }
    else {
      croak ref($self).'->endpoints: an endpoint is a hashref or a Kubernetes::Comb::Endpoint, got '
        .( ref $endpoint || 'a plain scalar' );
    }
    croak ref($self).'->endpoints: an endpoint has no name'
      unless defined $declared{name} && length $declared{name};
    my $problem = $self->endpoint_class->name_problem( $declared{name} );
    croak ref($self).'->endpoints: '.$problem if defined $problem;
    croak ref($self).'->endpoints: endpoint '.$declared{name}.' is declared twice'
      if $seen{ $declared{name} }++;
    push @declared, \%declared;
  }
  return @declared;
}

sub _endpoint_names {
  my ( $self ) = @_;
  return map { $_->{name} } $self->_declared_endpoints;
}

####
#### Upstream and bridge internals
####

# The upstream path up to the bridge, shared by reconcile, status and the
# endpoints: Future of { upstream, seen (what its status said), via,
# endpoints (redirected), items (the bridge, ready to apply) } as far as it
# got, and where it cannot go on stop => [ phase, reason, message ]. Never
# fails.
sub _observe_upstream {
  my ( $self, $upstream ) = @_;
  my %o = ( upstream => $upstream );
  my $stop = sub {
    my ( $phase, $reason, $message ) = @_;
    return Future->fail( $message, stop => $phase, $reason );
  };
  return $self->_hook( sub { $upstream->status( $_[0] ) } )->then(
    sub {
      my ( $seen ) = @_;
      return $stop->( Error => UpstreamFailed => ref($upstream).'->status answered '
        .( ref $seen || 'a plain scalar' ).', not a hashref' ) unless ref $seen eq 'HASH';
      $o{seen} = $seen;
      my $via = $seen->{via} // [];
      return $stop->( Error => UpstreamFailed => ref($upstream).'->status answered a via that is no arrayref' )
        unless ref $via eq 'ARRAY';
      # A chain longer than that is taken for a loop, recorded cut to that
      # length: a loop then records the same via every step, not a growing one.
      my @via = @$via;
      my $max = $self->max_upstream_depth;
      my $loop = @via > $max;
      splice @via, $max if $loop;
      $o{via} = \@via;
      my $label = $self->_upstream_label( \%o );
      return $stop->( Blocked => UpstreamUnreachable => $label.' is unreachable'.$self->_upstream_says( $seen, ': ' ) )
        unless $seen->{reachable};
      return $stop->( Blocked => UpstreamLoop => $label.' leads through more than '.$max.' layers, a loop? via '
        .join( ', ', @via ) ) if $loop;
      return $self->_hook( sub { $upstream->endpoints( $_[0] ) } )->else( sub {
        $stop->( Error => UpstreamFailed => 'reading the endpoints of '.$label.' failed: '.$self->_message( $_[0] ) );
      } );
    },
    sub {
      $stop->( Error => UpstreamFailed => 'reading the status of '.ref($upstream).' failed: '.$self->_message( $_[0] ) );
    }
  )->then( sub {
    my @offered = @_ == 1 && ref $_[0] eq 'ARRAY' ? @{ $_[0] } : @_;
    my @wrong = grep { !( blessed $_ && $_->isa('Kubernetes::Comb::Endpoint') ) } @offered;
    return $stop->( Error => UpstreamFailed => ref($upstream).'->endpoints answered '
      .( ref $wrong[0] || 'a plain scalar' ).', not a Kubernetes::Comb::Endpoint' ) if @wrong;
    my ( $redirected, $missing ) = $self->_redirect(@offered);
    if (@$missing) {
      my $phase = $o{seen}{phase};
      return $stop->( Blocked => UpstreamEndpointsMissing => $self->_upstream_label( \%o )
        .' offers no reachable address for endpoint(s) '.join( ', ', @$missing )
        .( defined $phase && $phase ne 'Running' ? ' (it is '.$phase.')' : '' )
        .$self->_upstream_says( $o{seen}, '; ' ) );
    }
    $o{endpoints} = $redirected;
    return $self->_hook( bridge_manifests => @$redirected )
      ->then( sub { Future->done( $self->_items(@_) ) } )
      ->else( sub {
        my ( $error, $category ) = @_;
        return $stop->( Blocked => BridgeImpossible => 'the upstream cannot be bridged: '.$self->_message($error) )
          if ( $category // '' ) eq 'bridge';
        return $stop->( Error => BridgeFailed => 'rendering the bridge failed: '.$self->_message($error) );
      } );
  } )->then(
    sub {
      $o{items} = [@_];
      return Future->done( \%o );
    },
    sub {
      my ( $message, $category, $phase, $reason ) = @_;
      $o{stop} = ( $category // '' ) eq 'stop'
        ? [ $phase, $reason, $message ]
        : [ Error => UpstreamFailed => 'borrowing from '.ref($upstream).' failed: '.$self->_message($message) ];
      return Future->done( \%o );
    }
  );
}

# The declared endpoints, each with the address of the upstream's endpoint
# of that name: ( [ redirected ], [ names the upstream has no address for ] ).
sub _redirect {
  my ( $self, @offered ) = @_;
  my %offered = map { ( $_->name => $_ ) } @offered;
  my ( @redirected, @missing );
  for my $declared ( $self->_declared_endpoints ) {
    my $upstream = $offered{ $declared->{name} };
    my $address = !$upstream        ? undef
                : $upstream->has_cluster  ? $upstream->cluster
                : $upstream->has_external ? $upstream->external
                :                           undef;
    unless ( defined $address && length $address ) {
      push @missing, $declared->{name};
      next;
    }
    my ( $host, $port ) = $self->_split_address($address);
    $address = $self->_join_address( $host, $upstream->port ) if defined $host && !defined $port;
    push @redirected, $self->endpoint_class->new(
      name    => $declared->{name},
      port    => $declared->{port},
      ( defined $declared->{protocol} ? ( protocol => $declared->{protocol} ) : () ),
      cluster => $address,
      ( $upstream->has_external ? ( external => $upstream->external ) : () )
    );
  }
  return ( \@redirected, \@missing );
}

sub _upstream_label {
  my ( $self, $o ) = @_;
  my $context = $o->{seen} ? $o->{seen}{context} : undef;
  return 'upstream '.ref( $o->{upstream} ).( defined $context ? ' (context '.$context.')' : '' );
}

# The message of the upstream status, as status text behind $glue; else
# nothing.
sub _upstream_says {
  my ( $self, $seen, $glue ) = @_;
  my $message = $seen && defined $seen->{message} ? $self->_message( $seen->{message} ) : '';
  return length $message ? $glue.$message : '';
}

# Phase, reason and message of a bridge that is in place: Running when the
# upstream is, else Pending.
sub _borrowed_verdict {
  my ( $self, $o ) = @_;
  my $label = $self->_upstream_label($o);
  my $phase = $o->{seen}{phase};
  return ( Running => Borrowed => 'borrowed from '.$label
    .( @{ $o->{via} } ? ' via '.join( ', ', @{ $o->{via} } ) : '' ) )
    if defined $phase && $phase eq 'Running';
  return ( Pending => UpstreamNotRunning => $label.' is '.( defined $phase ? $phase : 'in no known phase' )
    .$self->_upstream_says( $o->{seen}, ': ' ) );
}

# status.upstream as far as the upstream answered.
sub _upstream_record {
  my ( $self, $o ) = @_;
  my $seen = $o->{seen} // {};
  return {
    class      => ref $o->{upstream},
    ( defined $seen->{context} ? ( context   => ''.$seen->{context} )                          : () ),
    ( exists $seen->{reachable} ? ( reachable => $seen->{reachable} ? JSON->true : JSON->false ) : () ),
    ( defined $seen->{phase}   ? ( phase     => ''.$seen->{phase} )                            : () ),
    ( $o->{via}                ? ( via       => [ map { ''.$_ } @{ $o->{via} } ] )             : () ),
    observedAt => $self->_now
  };
}

# The bridge of one Service: ( [ manifests ], [ why it cannot be ] ).
sub _bridge_service {
  my ( $self, $service, @endpoints ) = @_;
  my ( @targets, @problems );
  for my $endpoint (@endpoints) {
    my $address = $endpoint->has_cluster ? $endpoint->cluster : undef;
    my ( $host, $port ) = defined $address ? $self->_split_address($address) : ();
    unless ( defined $host && defined $port ) {
      push @problems, 'endpoint '.$endpoint->name.' has '
        .( defined $address ? 'the address '.$address.', not host:port' : 'no address' );
      next;
    }
    my ( $family, $ip ) = $self->_ip_address($host);
    push @targets, {
      endpoint => $endpoint,
      host     => $family ? $ip : lc $host,
      port     => $port,
      family   => $family
    };
  }
  return ( [], \@problems ) if @problems;
  my %families = map { ( $_->{family} => 1 ) } @targets;
  if ( keys %families > 1 ) {
    my $what = $families{''} ? 'host names and IP addresses' : 'IPv4 and IPv6 addresses';
    return ( [], [ 'Service '.$service.': its endpoints point at both '.$what.' ('
      .join( ', ', map { $_->{endpoint}->name.' at '.$_->{host} } @targets ).'), one Service cannot bridge both' ] );
  }
  my @ports = map { +{
    name     => $_->{endpoint}->name,
    port     => $_->{endpoint}->port,
    protocol => $self->_service_protocol( $_->{endpoint}->protocol )
  } } @targets;
  return $families{''}
    ? $self->_bridge_external_name( $service, \@ports, @targets )
    : $self->_bridge_endpoint_slices( $service, \@ports, @targets );
}

sub _bridge_external_name {
  my ( $self, $service, $ports, @targets ) = @_;
  my @problems;
  my %hosts = map { ( $_->{host} => 1 ) } @targets;
  push @problems, 'Service '.$service.': an ExternalName Service points at one host, but its endpoints are at '
    .join( ', ', map { $_->{endpoint}->name.' at '.$_->{host} } @targets ) if keys %hosts > 1;
  push @problems, map {
    'Service '.$service.': endpoint '.$_->{endpoint}->name.' is port '.$_->{endpoint}->port.' here but '
      .$_->{port}.' at '.$_->{host}.', and an ExternalName Service cannot map ports'
  } grep { $_->{port} != $_->{endpoint}->port } @targets;
  return ( [], \@problems ) if @problems;
  my $host = $targets[0]{host};
  $host .= '.'.$self->cluster_domain if $host =~ /\.svc\z/;
  return ( [ {
    apiVersion => 'v1',
    kind       => 'Service',
    metadata   => { name => $service },
    spec       => { type => 'ExternalName', externalName => $host, ports => $ports }
  } ], [] );
}

# A selector-less Service, and one EndpointSlice per address: the endpoints
# of a slice serve all its ports.
sub _bridge_endpoint_slices {
  my ( $self, $service, $ports, @targets ) = @_;
  my $family = $targets[0]{family};
  my ( @addresses, %ports_at );
  for my $target (@targets) {
    push @addresses, $target->{host} unless $ports_at{ $target->{host} };
    push @{ $ports_at{ $target->{host} } }, {
      name     => $target->{endpoint}->name,
      port     => $target->{port},
      protocol => $self->_service_protocol( $target->{endpoint}->protocol )
    };
  }
  my $n = 0;
  return ( [
    {
      apiVersion => 'v1',
      kind       => 'Service',
      metadata   => { name => $service },
      spec       => { ipFamilies => [ $family ], ipFamilyPolicy => 'SingleStack', ports => $ports }
    },
    map { +{
      apiVersion  => 'discovery.k8s.io/v1',
      kind        => 'EndpointSlice',
      metadata    => {
        name   => $service.'-'.++$n,
        labels => {
          'kubernetes.io/service-name'             => $service,
          'endpointslice.kubernetes.io/managed-by' => $self->managed_by
        }
      },
      addressType => $family,
      ports       => $ports_at{$_},
      endpoints   => [ { addresses => [ $_ ] } ]
    } } @addresses
  ], [] );
}

sub _service_protocol {
  my ( $self, $protocol ) = @_;
  my $upper = uc( $protocol // 'tcp' );
  return $upper eq 'UDP' || $upper eq 'SCTP' ? $upper : 'TCP';
}

# host:port, [v6]:port, or either without the port: ( host, port or undef );
# nothing for what is none of these.
sub _split_address {
  my ( $self, $address ) = @_;
  return ( $1, $2 ) if $address =~ /\A\[([^\[\]\s]+)\](?::(\d+))?\z/;
  return ( $1, $2 ) if $address =~ /\A([^:\[\]\s]+)(?::(\d+))?\z/;
  my ( $family ) = $self->_ip_address($address);
  return ( $address, undef ) if $family eq 'IPv6';
  return;
}

sub _join_address {
  my ( $self, $host, $port ) = @_;
  my ( $family ) = $self->_ip_address($host);
  return ( $family eq 'IPv6' ? '['.$host.']' : $host ).':'.$port;
}

# ( IPv4 or IPv6, the address in canonical form ), or ( '' ) for a host name.
sub _ip_address {
  my ( $self, $host ) = @_;
  for my $family ( [ IPv4 => AF_INET ], [ IPv6 => AF_INET6 ] ) {
    my $packed = inet_pton( $family->[1], $host );
    return ( $family->[0], inet_ntop( $family->[1], $packed ) ) if defined $packed;
  }
  return ('');
}

####
#### Reconcile internals
####

# One reconcile step works on $r: previous (the recorded status it started
# from), conditions (type => { status, reason, message }), upstream (the
# resolved one, undef for local; absent while unresolved), then phase, reason
# and message, and -- where a step knows them -- managed (resource hashrefs)
# and endpoints (Kubernetes::Comb::Endpoint). established says which path
# settled what serves: local once the local path is through (healthy, or
# deployed and pruned), upstream once the upstream path observed its
# upstream. Each step either finishes $r or hands it to the next; a step
# whose own work fails finishes it as Error.

sub _status_class  { 'Kubernetes::Comb::CRD::CombStatus' }
sub _upstream_role { 'Kubernetes::Comb::Role::Upstream' }

sub _finish {
  my ( $self, $r, $phase, $reason, $message ) = @_;
  @{$r}{qw( phase reason message )} = ( $phase, $reason, $message );
  return Future->done($r);
}

sub _condition {
  my ( $self, $r, $type, $status, $reason, $message ) = @_;
  $r->{conditions}{$type} = { status => $status, reason => $reason, message => $message };
  return;
}

# An error as status text: without the trailing whitespace, and without the
# " at FILE line N." -- or "..., <FH> line N." -- that die and croak append
# when the text has no newline of its own.
sub _message {
  my ( $self, $error ) = @_;
  return 'unknown error' unless defined $error;
  return ( ''.$error ) =~ s/\s+\z//r
    =~ s/\s+at (?:\(eval \d+\)|\S+) line \d+(?:, <[^>]*> (?:line|chunk) \d+)?\.\z//r;
}

# Step 1, then on.
sub _reconcile_steps {
  my ( $self, $r ) = @_;
  return $self->_resolve_upstream->then(
    sub {
      ( $r->{upstream} ) = @_;
      return $self->_reconcile_enabled($r);
    },
    sub {
      $self->_finish( $r, Error => UpstreamFailed => 'resolving the upstream failed: '.$self->_message( $_[0] ) );
    }
  );
}

# Steps 2 and 3.
sub _reconcile_enabled {
  my ( $self, $r ) = @_;
  my $off = $self->_disabled_because;
  return $self->_finish( $r, Disabled => Disabled => $off ) if defined $off;
  return $self->_unmet_dependencies->then(
    sub {
      my @unmet = @_;
      unless (@unmet) {
        $self->_condition( $r, DependenciesReady => True => Healthy => 'all dependencies are healthy' );
        return $self->_reconcile_check($r);
      }
      my $message = join '; ', map { $_->{message} } @unmet;
      $self->_condition( $r, DependenciesReady => False => $unmet[0]{reason}, $message );
      return $self->_finish( $r, Blocked => $unmet[0]{reason}, $message );
    },
    sub {
      $self->_finish( $r, Error => DependenciesFailed => 'reading the dependencies failed: '.$self->_message( $_[0] ) );
    }
  );
}

sub _disabled_because {
  my ( $self ) = @_;
  my $spec = $self->has_crd ? $self->crd->spec : undef;
  my $enabled = $spec ? $spec->enabled : undef;
  return defined $enabled ? ( $enabled ? undef : 'spec.enabled is false' )
       : $self->optional   ? ref($self).' is optional and spec.enabled is not set'
       :                     undef;
}

# Future of one { reason, message } per dependency that is not there.
sub _unmet_dependencies {
  my ( $self ) = @_;
  return Future->call( sub {
    my @refs = $self->depends_on;
    return Future->done unless @refs;
    return Future->done( {
      reason  => 'NoResolver',
      message => 'depends on '.join( ', ', @refs ).', but there is no resolver to find them'
    } ) unless $self->has_resolver;
    return Future->needs_all( map { $self->_unmet_dependency($_) } @refs );
  } );
}

sub _unmet_dependency {
  my ( $self, $ref ) = @_;
  return Future->call( sub {
    my $dependency = $self->resolver->( $ref, $self );
    return Future->done( { reason => 'DependencyNotFound', message => 'dependency '.$ref.' not found' } )
      unless defined $dependency;
    return Future->done( {
      reason  => 'DependencyInvalid',
      message => 'the resolver returned '.( ref $dependency || 'a plain scalar' ).' for '.$ref.', not a Comb'
    } ) unless blessed $dependency && $dependency->can('healthy');
    return $dependency->healthy->then(
      sub {
        return Future->done if $_[0];
        return Future->done( { reason => 'DependencyNotReady', message => 'dependency '.$ref.' is not healthy' } );
      },
      sub {
        return Future->done( {
          reason  => 'DependencyNotReady',
          message => 'dependency '.$ref.' is not healthy: '.$self->_message( $_[0] )
        } );
      }
    );
  } )->else( sub {
    Future->done( { reason => 'ResolverFailed', message => 'looking up '.$ref.' failed: '.$self->_message( $_[0] ) } );
  } );
}

# Step 4, then the path.
sub _reconcile_check {
  my ( $self, $r ) = @_;
  return $self->_hook('check')->then(
    sub {
      my @missing = @_;
      if (@missing) {
        my $message = 'missing: '.join( '; ', @missing );
        $self->_condition( $r, ConfigReady => False => MissingPrerequisites => $message );
        return $self->_finish( $r, NeedsConfig => MissingPrerequisites => $message );
      }
      $self->_condition( $r, ConfigReady => True => Complete => 'nothing missing' );
      return defined $r->{upstream} ? $self->_reconcile_upstream($r) : $self->_reconcile_local($r);
    },
    sub {
      my $message = 'check failed: '.$self->_message( $_[0] );
      $self->_condition( $r, ConfigReady => Unknown => CheckFailed => $message );
      return $self->_finish( $r, Error => CheckFailed => $message );
    }
  );
}

# Step 5a.
sub _reconcile_local {
  my ( $self, $r ) = @_;
  # After borrowing, the bridge may stand where the local resources belong,
  # and look healthy: deploy anyway.
  my $borrowed = $r->{previous} && $r->{previous}->upstream;
  return $self->_render->then(
    sub {
      my @items = @_;
      return $self->_observe_local(@items)->then(
        sub {
          my ( $live ) = @_;
          return $self->_deploy_and_prune( $r, $live, @items ) if !$live->{healthy} || $borrowed;
          my @changed = $self->_changed_items(@items);
          return $self->_deploy_changed( $r, \@changed, @items ) if @changed;
          return $self->_settle_record( $r, @items ) if $self->_record_differs( $r, @items );
          $r->{established} = 'local';
          return $self->_finish( $r, Running => Healthy => 'healthy' );
        },
        sub {
          $self->_finish( $r, Error => StatusFailed => 'reading the live status failed: '.$self->_message( $_[0] ) );
        }
      );
    },
    sub {
      $self->_finish( $r, Error => ManifestsFailed => 'rendering the manifests failed: '.$self->_message( $_[0] ) );
    }
  );
}

# Whether the rendered items and the recorded managedResources name
# different resources (by group, kind, namespace, name): something to prune
# -- dropped from the manifests, or a delete that failed -- or something
# that runs but is not recorded.
sub _record_differs {
  my ( $self, $r, @items ) = @_;
  my %recorded = map { ( $self->_resource_key($_) => 1 ) } $self->_previous_resources($r);
  my %rendered = map { ( $self->_resource_key( $self->_resource_of($_) ) => 1 ) } @items;
  return 1 if keys %recorded != keys %rendered;
  return grep( { !$recorded{$_} } keys %rendered ) ? 1 : 0;
}

# The items whose live object was applied from another manifest than the
# one rendered now, or from one without a digest.
sub _changed_items {
  my ( $self, @items ) = @_;
  return grep {
    $self->_digest_counts($_) && ( $self->_live_digest($_) // '' ) ne $_->{digest}
  } @items;
}

sub _live_digest {
  my ( $self, $item ) = @_;
  my $annotations = $item->{live}->metadata->annotations;
  return ref $annotations eq 'HASH' ? $annotations->{ $self->applied_digest_annotation } : undef;
}

# Whether the digest of the live object says what this Comb applied. Not
# where another deploy would not change it, or reconcile would deploy every
# step: what the client leaves as it is, and what a same-named Comb of
# another namespace applied last (see _fetch_live) -- its labels, and so its
# digest, are that Comb's.
sub _digest_counts {
  my ( $self, $item ) = @_;
  my $live = $item->{live} or return 0;
  my $owner = ( $live->metadata->labels // {} )->{ $self->comb_namespace_label };
  return 0 if defined $owner && $owner ne $self->namespace;
  return $self->_kept_by_ensure($item) ? 0 : 1;
}

# What ensure of Kubernetes::REST and Net::Async::Kubernetes returns as it
# found it: a core/v1 PersistentVolumeClaim, and a batch/v1 Job that runs or
# has succeeded. Any other Job it replaces. By the exact apiVersion, as they
# tell.
sub _kept_by_ensure {
  my ( $self, $item ) = @_;
  my $resource = $item->{apiVersion}.'/'.$item->{kind};
  return 1 if $resource eq 'v1/PersistentVolumeClaim';
  return 0 unless $resource eq 'batch/v1/Job';
  my $status = $item->{live}->TO_JSON->{status};
  return ref $status eq 'HASH' && ( $status->{succeeded} || $status->{active} ) ? 1 : 0;
}

# A healthy Comb that renders something else than it applied: deploy and
# prune. What is live and healthy is what was rendered before, so whether
# the Comb is Running is for the next step to see.
sub _deploy_changed {
  my ( $self, $r, $changed, @items ) = @_;
  my ( @differ, @without );
  push @{ defined $self->_live_digest($_) ? \@differ : \@without }, $_->{kind}.' '.$_->{name} for @$changed;
  return $self->_deploy_pending( $r, join( '; ',
    ( @differ  ? 'rendered differently now: '.join( ', ', @differ )   : () ),
    ( @without ? 'applied without a digest: '.join( ', ', @without ) : () )
  ), @items );
}

# A healthy Comb whose record differs: deploy and prune all the same, so
# the debt is paid while it runs. Everything rendered was live and healthy
# before, and applied as rendered, so it stays Running.
sub _settle_record {
  my ( $self, $r, @items ) = @_;
  return $self->_apply_and_prune( $r, sub {
    $r->{established} = 'local';
    $self->_finish( $r, Running => Healthy => join '; ',
      'healthy', 'the record differed from the manifests: applied '.scalar(@items).' resource(s)', @_ );
  }, @items );
}

# Step 5b, the upstream path: upstream status and endpoints, replicate_into,
# the bridge; it fills phase, managed, endpoints and upstream_status of $r.
sub _reconcile_upstream {
  my ( $self, $r ) = @_;
  my $upstream = $r->{upstream};
  return $self->_observe_upstream($upstream)->then( sub {
    my ( $o ) = @_;
    $r->{established} = 'upstream';
    $r->{upstream_status} = $self->_upstream_record($o);
    $r->{endpoints} = $o->{endpoints} if $o->{endpoints};
    return $self->_finish( $r, @{ $o->{stop} } ) if $o->{stop};
    my $replicated = $upstream->can('replicate_into')
      ? $self->_hook( sub { $upstream->replicate_into( $_[0] ) } )
      : Future->done;
    return $replicated->then(
      sub {
        $self->_apply_and_prune( $r, sub {
          my ( $phase, $reason, $message ) = $self->_borrowed_verdict($o);
          return $self->_finish( $r, $phase, $reason, join '; ', $message, @_ );
        }, @{ $o->{items} } );
      },
      sub {
        $self->_finish( $r, Error => ReplicationFailed => 'replicating from '.$self->_upstream_label($o)
          .' failed: '.$self->_message( $_[0] ) );
      }
    );
  } );
}

sub _deploy_and_prune {
  my ( $self, $r, $live, @items ) = @_;
  my $state = $live->{healthy} ? 'in place of the bridge'
            : 'not healthy yet'.( $live->{phase} ne 'NotDeployed' && $live->{message} ? ' ('.$live->{message}.')' : '' );
  return $self->_deploy_pending( $r, $state, @items );
}

# Deploy and prune, then Pending, the message saying why it deployed.
sub _deploy_pending {
  my ( $self, $r, $why, @items ) = @_;
  return $self->_apply_and_prune( $r, sub {
    $r->{established} = 'local';
    $self->_finish( $r, Pending => Deployed => join '; ', 'applied '.scalar(@items).' resource(s), '.$why, @_ );
  }, @items );
}

# Applies the items, then prunes what the record has and they do not; sets
# managed of $r. $done gets the notes of the pruning and finishes $r; a
# failed apply finishes it as Error.
sub _apply_and_prune {
  my ( $self, $r, $done, @items ) = @_;
  my @previous = $self->_previous_resources($r);
  my @desired  = map { $self->_resource_of($_) } @items;
  return $self->_apply(@items)->then(
    sub {
      my %desired = map { ( $self->_resource_key($_) => 1 ) } @desired;
      return $self->_prune( grep { !$desired{ $self->_resource_key($_) } } @previous )->then( sub {
        my @pruned = @_;
        $r->{managed} = $self->_union( \@desired, [ map { $_->{resource} } grep { $_->{keep} } @pruned ] );
        return $done->( map { $_->{note} // () } @pruned );
      } );
    },
    sub {
      my ( $error, $category, $details ) = @_;
      # _apply goes one after the other: what it applied are the first items
      my $applied = ( $category // '' ) eq 'deploy' && ref $details eq 'HASH'
        ? scalar @{ $details->{applied} // [] }
        : 0;
      $r->{managed} = $self->_union( [ @desired[ 0 .. $applied - 1 ] ], \@previous );
      return $self->_finish( $r, Error => DeployFailed => 'deploy failed: '.$self->_message($error) );
    }
  );
}

sub _previous_resources {
  my ( $self, $r ) = @_;
  my $recorded = $r->{previous} ? $r->{previous}->managedResources : undef;
  return map { +{
    apiVersion => $_->apiVersion,
    kind       => $_->kind,
    ( defined $_->namespace ? ( namespace => $_->namespace ) : () ),
    name       => $_->name
  } } @{ $recorded // [] };
}

sub _resource_of {
  my ( $self, $item ) = @_;
  return {
    apiVersion => $item->{apiVersion},
    kind       => $item->{kind},
    ( defined $item->{namespace} ? ( namespace => $item->{namespace} ) : () ),
    name       => $item->{name}
  };
}

# Identity of a resource across API versions: group, kind, namespace, name.
sub _resource_key {
  my ( $self, $resource ) = @_;
  my ( $group ) = $resource->{apiVersion} =~ m{\A(.+)/[^/]+\z};
  return join "\0", $group // '', $resource->{kind}, $resource->{namespace} // '', $resource->{name};
}

# The lists joined, the first of each identity kept.
sub _union {
  my ( $self, @lists ) = @_;
  my ( %seen, @union );
  for my $resource ( map { @$_ } @lists ) {
    push @union, $resource unless $seen{ $self->_resource_key($resource) }++;
  }
  return \@union;
}

# Future of { resource, keep, note } per orphan; never fails. A
# cluster-scoped orphan is left in place. An orphan that still carries the
# Comb labels is deleted, with propagationPolicy Background: what it owns --
# the Pods of a Job, the ReplicaSets of a Deployment -- goes with it. One
# that does not carry them is gone or no longer this Comb's -- not ours to
# delete either way. A failed check or delete keeps it for the next step.
sub _prune {
  my ( $self, @orphans ) = @_;
  my ( @left, %groups );
  for my $orphan (@orphans) {
    if ( $self->_cluster_scoped($orphan) ) {
      push @left, {
        resource => $orphan,
        keep     => 0,
        note     => 'left '.$orphan->{kind}.' '.$orphan->{name}.' in place: cluster-scoped, never pruned automatically'
      };
      next;
    }
    push @{ $groups{ $orphan->{apiVersion}.'/'.$orphan->{kind} }{ $orphan->{namespace} // '' } }, $orphan;
  }
  return Future->done(@left) unless %groups;
  return Future->needs_all( map {
    my $resource = $_;
    map {
      my ( $namespace, $members ) = ( $_, $groups{$resource}{$_} );
      $self->k8s->list( $resource,
        ( length $namespace ? ( namespace => $namespace ) : () ),
        labelSelector => $self->label_selector
      )->then(
        sub {
          my %live = map { ( $_->metadata->name => $_ ) } @{ $_[0]->items // [] };
          return Future->needs_all( map { $self->_prune_one( $resource, $_, $live{ $_->{name} } ) } @$members );
        },
        sub {
          my $error = $self->_message( $_[0] );
          return Future->done( map { +{
            resource => $_,
            keep     => 1,
            note     => 'could not check '.$_->{kind}.' '.$_->{name}.' for pruning: '.$error
          } } @$members );
        }
      );
    } sort keys %{ $groups{$resource} };
  } sort keys %groups )->then( sub { Future->done( @left, @_ ) } );
}

# Cluster-scoped: a Namespace takes everything in it along, a
# CustomResourceDefinition every object of its kind, and a same-named Comb of
# another namespace may render it too. Recorded without a namespace means it
# was applied as one.
sub _cluster_scoped {
  my ( $self, $resource ) = @_;
  return 1 unless defined $resource->{namespace};
  return $self->_namespaced( undef, $resource ) ? 0 : 1;
}

sub _prune_one {
  my ( $self, $resource, $orphan, $live ) = @_;
  my $what = $orphan->{kind}.' '.$orphan->{name};
  return $self->k8s->delete( $live, propagationPolicy => 'Background' )->then(
    sub { Future->done( { resource => $orphan, keep => 0 } ) },
    sub {
      Future->done( {
        resource => $orphan,
        keep     => 1,
        note     => 'deleting '.$what.' failed: '.$self->_message( $_[0] )
      } );
    }
  ) if $live;
  return $self->k8s->get( $resource, $orphan->{name},
    ( defined $orphan->{namespace} ? ( namespace => $orphan->{namespace} ) : () )
  )->then(
    sub {
      Future->done( {
        resource => $orphan,
        keep     => 0,
        note     => 'left '.$what.' alone: it no longer carries '.$self->label_selector
      } );
    },
    sub { Future->done( { resource => $orphan, keep => 0 } ) }
  );
}

# Step 1: Future of the upstream object, or of nothing for local. The first
# source that exists decides.
sub _resolve_upstream {
  my ( $self ) = @_;
  return Future->call( sub {
    if ( $self->_has_upstream ) {
      my $given = $self->_upstream;
      return $self->_hook($given)->then( sub {
        Future->done( $self->_upstream_from( 'the upstream coderef', @_ ) );
      } ) if ref $given eq 'CODE';
      return Future->done(
        $self->_upstream_from( 'the upstream argument', ref $given eq 'ARRAY' ? @$given : $given )
      );
    }
    my $spec = $self->has_crd ? $self->crd->spec : undef;
    return Future->done( $self->_upstream_from( 'spec.upstream', $spec->upstream ) )
      if $spec && $spec->has_upstream;
    return $self->_hook('upstream')->then( sub {
      Future->done( $self->_upstream_from( ref($self).'->upstream', @_ ) );
    } ) if $self->can('upstream');
    return Future->done;
  } );
}

# One answer: nothing (local), an upstream object, a hashref as in the custom
# resource, or Name => (%args) / '+Full::Class' => (%args).
sub _upstream_from {
  my ( $self, $source, @answer ) = @_;
  return if !@answer || ( @answer == 1 && !defined $answer[0] );
  my ( $first, @args ) = @answer;
  if ( ref $first ) {
    croak $source.': one upstream object or hashref, not a list of '.scalar(@answer) if @args;
    return $self->_checked_upstream( $source, $first ) if blessed $first;
    croak $source.': expected nothing, an upstream object, a hashref or Name => (...), got a '
      .ref($first).' reference' unless ref $first eq 'HASH';
    my %spec = %$first;
    my $class = delete $spec{class};
    croak $source.' names no class' unless defined $class && length $class;
    return $self->_build_upstream( $source, $class, %spec );
  }
  croak $source.': expected nothing, an upstream object, a hashref or Name => (...), got a list starting with undef'
    unless defined $first;
  croak $source.': '.$first.' => (...) needs key/value pairs' if @args % 2;
  return $self->_build_upstream( $source, $self->_upstream_class($first), @args );
}

sub _upstream_class {
  my ( $self, $name ) = @_;
  return $name =~ /\A\+(.+)\z/ ? $1 : 'Kubernetes::Comb::Upstream::'.$name;
}

# Checked before it is built: a class the custom resource names gets no
# constructor call unless it is an upstream.
sub _build_upstream {
  my ( $self, $source, $class, @args ) = @_;
  use_module($class) unless $class->can('new');
  croak $source.': '.$class.' does not do '.$self->_upstream_role
    unless $class->DOES( $self->_upstream_role );
  return $self->_checked_upstream( $source, $class->new(@args) );
}

sub _checked_upstream {
  my ( $self, $source, $upstream ) = @_;
  croak $source.': '.ref($upstream).' does not do '.$self->_upstream_role
    unless $upstream->DOES( $self->_upstream_role );
  return $upstream;
}

# Step 6, first half: the resolved local endpoints once the local path
# established them. The upstream path brings its own; a step that
# established nothing carries the previous ones forward (see _status_from)
# -- unless there are none, then a local Comb publishes its own.
sub _publish_endpoints {
  my ( $self, $r ) = @_;
  my $established = $r->{established} // '';
  my $local = $established eq 'local'
    || ( !$established && !$r->{previous} && exists $r->{upstream} && !defined $r->{upstream} );
  return Future->done($r) if $r->{endpoints} || !$local;
  return Future->call( sub { Future->done( $self->_local_endpoints ) } )->then(
    sub {
      $r->{endpoints} = [@_];
      return Future->done($r);
    },
    sub {
      return Future->done($r) if $r->{phase} eq 'Error';
      return $self->_finish( $r, Error => EndpointsFailed => 'resolving the endpoints failed: '.$self->_message( $_[0] ) );
    }
  );
}

# Step 6: into the custom resource, else into memory.
sub _record {
  my ( $self, $r ) = @_;
  my $status = $self->_status_from($r);
  unless ( $self->has_crd ) {
    $self->_memory_status($status);
    return Future->done($status);
  }
  return Future->call( sub { $self->_write_status($status) } )->then(
    sub {
      my ( $stored ) = @_;
      $self->_set_crd($stored);
      return Future->done( $stored->status // $status );
    },
    sub {
      # Keep what this step did, so the next one prunes against it.
      $self->_condition( $r, StatusWritten => False => WriteFailed =>
        'writing the status into the custom resource failed: '.$self->_message( $_[0] ) );
      my $kept = $self->_status_from($r);
      $self->_set_crd( $self->_crd_with( $self->crd, $kept ) );
      return Future->done($kept);
    }
  );
}

# update_status on a copy of the custom resource; if that fails -- a
# resourceVersion conflict looks like any other error -- once more on a fresh
# read of it.
sub _write_status {
  my ( $self, $status ) = @_;
  return $self->k8s->update_status( $self->_crd_with( $self->crd, $status ) )->else( sub {
    my $meta = $self->crd->metadata;
    return $self->k8s->get( '+'.$self->crd_class, $meta->name, namespace => $meta->namespace )->then( sub {
      my ( $fresh ) = @_;
      $self->_set_crd($fresh);
      return $self->k8s->update_status( $self->_crd_with( $fresh, $status ) );
    } );
  } );
}

sub _crd_with {
  my ( $self, $crd, $status ) = @_;
  my $copy = ref($crd)->FROM_HASH( $crd->TO_JSON );
  $copy->status($status);
  return $copy;
}

sub _status_from {
  my ( $self, $r ) = @_;
  my $now = $self->_now;
  my %before = map { ( $_->type => $_ ) } @{ ( $r->{previous} ? $r->{previous}->conditions : undef ) // [] };
  my %unchecked = ( status => 'Unknown', reason => 'NotChecked', message => 'this step did not get that far' );
  my %conditions = (
    DependenciesReady => {%unchecked},
    ConfigReady       => {%unchecked},
    %{ $r->{conditions} },
    Ready => {
      status  => $r->{phase} eq 'Running' ? 'True' : 'False',
      reason  => $r->{reason},
      message => $r->{message}
    }
  );
  my @fixed = qw( Ready DependenciesReady ConfigReady );
  my %fixed = map { ( $_ => 1 ) } @fixed;
  my $meta = $self->has_crd ? $self->crd->metadata : undef;
  my $generation = $meta ? $meta->generation : undef;
  # A step that established nothing -- it stopped before a path, or the
  # local path failed before it was through -- changed nothing that serves:
  # the endpoints and the upstream recorded before still stand, like
  # managedResources. So a bridge stays known until the local path replaced
  # it.
  my $carried = $r->{established} ? undef : $r->{previous};
  my @endpoints = $r->{endpoints} ? ( map { $_->to_crd } @{ $r->{endpoints} } )
                : $carried        ? ( map { $_->TO_JSON } @{ $carried->endpoints // [] } )
                :                   ();
  my $upstream = $r->{upstream_status}
    // ( $carried && $carried->upstream ? $carried->upstream->TO_JSON : undef );
  return $self->_status_class->new(
    phase            => $r->{phase},
    conditions       => [ map {
      my ( $type, $condition, $was ) = ( $_, $conditions{$_}, $before{$_} );
      +{
        type               => $type,
        status             => $condition->{status},
        ( defined $condition->{reason}  ? ( reason  => $condition->{reason} )  : () ),
        ( defined $condition->{message} ? ( message => $condition->{message} ) : () ),
        lastTransitionTime => $was && $was->status eq $condition->{status} && defined $was->lastTransitionTime
          ? $was->lastTransitionTime
          : $now
      };
    } @fixed, sort grep { !$fixed{$_} } keys %conditions ],
    managedResources => $r->{managed} // [ $self->_previous_resources($r) ],
    endpoints        => \@endpoints,
    ( $upstream           ? ( upstream           => $upstream )   : () ),
    ( defined $generation ? ( observedGeneration => $generation ) : () )
  );
}

# When even the status could not be built: the bare minimum, not written.
sub _last_resort {
  my ( $self, $error ) = @_;
  my $status = eval {
    $self->_status_class->new(
      phase      => 'Error',
      conditions => [ {
        type               => 'Ready',
        status             => 'False',
        reason             => 'ReconcileFailed',
        message            => 'recording the status failed: '.$self->_message($error),
        lastTransitionTime => $self->_now
      } ]
    );
  };
  $self->_memory_status($status) if $status && !$self->has_crd;
  return $status;
}

sub _now { strftime( '%Y-%m-%dT%H:%M:%SZ', gmtime ) }


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Kubernetes::Comb - A self-contained micro collection of Kubernetes parts as a live Perl instance

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  package MyApp::Comb::NATS;
  use Moo;
  extends 'Kubernetes::Comb';

  sub endpoints { { name => 'client', port => 4222 } }

  sub manifests {
    my ( $self ) = @_;
    return (
      { apiVersion => 'apps/v1', kind => 'Deployment', metadata => { name => 'nats' }, spec => { ... } },
      { apiVersion => 'v1',      kind => 'Service',    metadata => { name => 'nats' }, spec => { ... } }
    );
  }

  package main;

  my $comb = Kubernetes::Comb->from_crd($cr,
    k8s      => $k8s,                             # default: Kubernetes::Comb::Client::Sync
    resolver => sub { $combs{ $_[0] } },
    stub     => sub { $_[0]->name eq 'mailer' }
  );

  $comb->deploy->get;
  my $status = $comb->status->get;      # { phase => 'Running', healthy => 1, pods => [...] }
  print $comb->logs(lines => 50)->get;
  my $ep = $comb->endpoint('client')->get;
  print $ep->cluster;                   # nats.platform.svc:4222

=head1 DESCRIPTION

A Comb is one cell of a honeycomb: a named set of Kubernetes parts that
deploys itself, reports its status and publishes its endpoints. Controlling
code builds the instance -- usually with L</from_crd> from a C<Comb> custom
resource -- and from then on only calls its methods. All Kubernetes work
happens in here, through the L</k8s> client.

A Comb class extends this one and overrides the contract: L</name>,
L</depends_on>, L</endpoints>, L</manifests>, L</check>, L</optional>,
L</bridge_manifests>, L</stub_class>. It may also define a plain C<upstream>
method (where its service is borrowed from); this class deliberately defines
none, so whether a class has one is visible to C<can>.

Every lifecycle method -- L</reconcile>, L</deploy>, L</status>,
L</healthy>, L</logs>, L</restart>, L</stop>, L</describe>, L</endpoint> --
returns a L<Future> and never throws: any error, including one in a contract
method, is a failed Future. L</reconcile> goes further: its Future never
fails at all.

=head1 WHAT A MANAGER MUST DO

Kubernetes::Comb ships no manager or daemon: whoever drives Combs does it from
their own program, sync or async, with one step repeated:

=over

=item 1. Watch or list C<Comb> custom resources.

=item 2. Build an instance for each with L</from_crd>, passing C<k8s>,
C<resolver>, C<upstream> and C<stub> as the layering and stub choices call
for.

=item 3. Order the instances by L</depends_on> (topological sort; a cycle is
not an exception -- report it, and reconcile its Combs anyway: each stays
C<Blocked> on the other, and says so).

=item 4. Call L</reconcile> on each, repeatedly (a timer, on a CR change, or
both).

=item 5. Show or act on L</status>; call L</restart>, L</stop>, L</logs> on
request.

=back

F<examples/sync.pl> and F<examples/async.pl> do exactly this for three
Combs -- C<nats> local, C<db> replicated (L<Kubernetes::Comb::Upstream::Static>
or L<Kubernetes::Comb::Upstream::K8s>), C<mailer> as a stub -- and print every
state transition; run either with C<--help>.

=head2 k8s

The Kubernetes client, anything doing L<Kubernetes::Comb::Role::Client>.
Defaults to a L<Kubernetes::Comb::Client::Sync> on the current kube context;
pass a L<Kubernetes::Comb::Client::Async> to run on an L<IO::Async> loop.

=head2 resolver

Coderef that turns a dependency reference (C<name> or C<namespace/name>) into
the Comb instance. The only way a Comb finds its dependencies; supplied by the
controlling code. C<has_resolver> tells whether there is one.

=head2 upstream

Constructor argument: what the controlling code says about the upstream, the
first source of the upstream resolution. A coderef, called with the Comb and
returning what a class C<upstream> method returns; or that answer given
directly: an object doing C<Kubernetes::Comb::Role::Upstream>, a hashref as in
the custom resource (C<< { class => ..., ... } >>), an arrayref of the Perl
helper form (C<< [ K8s => ( context => 'dev' ) ] >>), or C<undef> for an
explicit "local". There is no reader of this name.

=head2 crd

The C<Comb> custom resource this instance was built from, if any. Name,
namespace, config and dependencies default to what it says, and the Comb
writes its status into it. C<has_crd> tells whether there is one.

=head2 crd_class

The custom resource class. Defaults to the class of L</crd>, else
L<Kubernetes::Comb::CRD::Comb>. A CR class for another API group is a
subclass of that, see L<Kubernetes::Comb::CRD::Comb>. Construction dies when a
given L</crd> is not an instance of it.

=head2 namespace

Where the Comb lives: its namespaced resources that name none get this one.
Defaults to the namespace of L</crd>; without either, every operation that
needs it fails.

=head2 config

Free-form configuration for the class. Defaults to a copy of C<spec.config>
of L</crd>, else an empty hashref.

=head2 label_prefix

Prefix of the label and annotation keys the Comb sets, default
C<comb.internal/>: the name label is C<E<lt>prefixE<gt>comb>, the namespace
label C<E<lt>prefixE<gt>comb-namespace>, the restart annotation
C<E<lt>prefixE<gt>restartedAt>, the digest annotation
C<E<lt>prefixE<gt>applied-digest>. Include the trailing C</>.

=head2 managed_by

Value of the C<app.kubernetes.io/managed-by> label on every resource the Comb
deploys. Default C<kubernetes-comb>.

=head2 max_upstream_depth

The most layers an upstream chain may have, default 16. An upstream whose
C<via> names more is taken for a loop -- C<Blocked>, see L</reconcile> --
and its C<via> is recorded cut to this length, so a loop never makes it
grow. Kube context names cannot tell a loop: layers may share one context
(namespaces of one cluster), and kubeconfigs name contexts alike.

=head2 cluster_domain

The DNS domain of the cluster, default C<cluster.local>. The default
L</bridge_manifests> appends it to a host ending in C<.svc> before it becomes
the C<externalName> of a Service: the cluster DNS answers that with a CNAME,
which a Pod's resolver does not expand with its search domains.

=head2 io_k8s

The L<IO::K8s> instance that tells the Comb what a manifest hashref is:
whether its Kind is namespaced, and its C<apiVersion> when it has none.
Defaults to one that knows the built-in Kinds and the Comb CR. Pass one with
your CRD providers (C<< IO::K8s->new(with => [...]) >>) when manifests
contain cluster-scoped custom resources; a Kind it does not know counts as
namespaced.

=head2 stub_of

The original Comb this instance stands in for, when it was built as its stub
(see L</from_crd>). Construction checks the contract: a stub that lacks any
endpoint name of its original dies, naming the missing ones. C<is_stub> tells
whether there is one.

A class named C<Foo::Stub> that is a C<Foo> -- the default L</stub_class> of
C<Foo> -- is checked against C<Foo> however it was selected: built without
C<stub_of>, e.g. because C<spec.class> names it directly, it builds a C<Foo>
from the same arguments to check against. That C<Foo> is not kept:
C<stub_of> stays unset.

=head2 name

The name of the Comb. Defaults to C<metadata.name> of L</crd>; a class used
without a custom resource overrides it. It goes into a label value on every
resource, so construction dies on a name that cannot be one: more than 63
characters, or other than letters, digits, C<->, C<_> and C<.> with a letter
or digit at both ends.

=head2 depends_on

List of the Combs this one needs, each C<name> or C<namespace/name>.
Defaults to C<spec.dependsOn> of L</crd>.

=head2 endpoints

List of what the Comb offers, each a hashref or a L<Kubernetes::Comb::Endpoint>.
A hashref has C<name> -- a DNS-1123 label, see
L<Kubernetes::Comb::Endpoint/name_problem> -- and C<port>, optionally
C<protocol> (default C<tcp>),
C<service> (the Service it is reached through, default L</name>),
C<external> and C<cluster> (both C<host:port>; C<cluster> defaults to
C<E<lt>serviceE<gt>.E<lt>namespaceE<gt>.svc:E<lt>portE<gt>>). Default: none.

=head2 manifests

List of the resources the Comb consists of, as L<IO::K8s> objects or
hashrefs -- or a Future of that list. Default: none.

=head2 check

List of the prerequisites that are missing, as human-readable strings -- or a
Future of that list. Empty means the Comb can go ahead. Default: nothing
missing.

=head2 optional

Whether the Comb stays off until it is switched on: with C<spec.enabled>
unset, L</reconcile> leaves an optional Comb C<Disabled> and runs any other
one. Default false. Works as class and as instance method.

=head2 bridge_manifests

  my @manifests = $comb->bridge_manifests(@endpoints)->get;

The resources that make the upstream reachable under the local names while an
upstream is active: for each Service the Comb would have locally, the one
that points at the upstream instead, so consumers keep using
C<E<lt>serviceE<gt>:E<lt>portE<gt>>. Called with the redirected endpoints
(L<Kubernetes::Comb::Endpoint>), whose C<cluster> is the upstream address to
point at; returns the manifests, or a Future of them. Override it when the
service needs more. A Future that fails with category C<bridge> says the
upstream cannot be bridged -- L</reconcile> reports that as C<Blocked> and
deploys nothing -- any other failure is an C<Error>.

The default groups the endpoints by their Service (C<service> of
L</endpoints>, default L</name>), each port named after its endpoint:

=over

=item * all host names: a Service of type C<ExternalName>. It cannot map
ports, so an upstream port that differs from the local one, or endpoints
pointing at different hosts, cannot be bridged. A host ending in C<.svc>
gets L</cluster_domain> appended.

=item * all IP addresses of one family: a selector-less Service
(C<ipFamilies> that family) plus an C<EndpointSlice> per address
(C<discovery.k8s.io/v1>, C<kubernetes.io/service-name> label), which may
point at another port.

=item * a mix of names and addresses, or of IPv4 and IPv6: cannot be
bridged.

=back

=head2 stub_class

The class that stands in for this one when a stub is asked for. Defaults to
C<E<lt>classE<gt>::Stub> if that class exists or loads -- a stub that fails to
compile dies --, else C<undef>. Works as class and as instance method.

=head2 endpoint_class

The class L</endpoint> builds, L<Kubernetes::Comb::Endpoint>.

=head2 from_crd

  my $comb = Kubernetes::Comb->from_crd($cr,
    k8s      => $k8s,
    resolver => sub { ... },
    upstream => sub { ... },
    stub     => sub { my ( $comb ) = @_; ... }
  );

Builds the Comb for a C<Comb> custom resource: loads C<spec.class> and
constructs it with C<< crd => $cr >> plus the options, all of which but
C<stub> go to the constructor. C<stub> is called with that instance; when it
returns true, the instance's L</stub_class> is built instead, with the
original as L</stub_of> -- which checks the stub keeps the original's
endpoints. A C<spec.class> naming a stub directly is checked as well, see
L</stub_of>. Dies when C<spec.class> is not a subclass of the invocant, a
stub is asked for and there is none, or construction dies.

=head2 comb_label

Key of the label that carries the Comb name: C<E<lt>label_prefixE<gt>comb>.

=head2 comb_namespace_label

Key of the label that carries the Comb namespace:
C<E<lt>label_prefixE<gt>comb-namespace>. Next to the name it tells the
resources of same-named Combs in different namespaces apart -- the layers of
one cluster -- where they share a namespace or are cluster-scoped.

=head2 comb_labels

Hashref of the labels every resource of the Comb gets, Pod templates of its
workloads included: L</comb_label> with the name, L</comb_namespace_label>
with the L</namespace>, and C<app.kubernetes.io/managed-by> with
L</managed_by>.

=head2 label_selector

Label selector for everything of this Comb:
C<E<lt>comb_labelE<gt>=E<lt>nameE<gt>,E<lt>comb_namespace_labelE<gt>=E<lt>namespaceE<gt>>.

=head2 restart_annotation

Pod template annotation L</restart> sets: C<E<lt>label_prefixE<gt>restartedAt>.

=head2 applied_digest_annotation

Annotation L</deploy> puts on every resource, holding the digest of the
manifest it was applied from: C<E<lt>label_prefixE<gt>applied-digest>.

=head2 reconcile

  my $status = $comb->reconcile->get;
  print $status->phase;

One step towards what the Comb class describes. Future of the new recorded
status, a L<Kubernetes::Comb::CRD::CombStatus> -- also what
L</recorded_status> returns afterwards. The Future never fails: whatever
goes wrong, a dying contract method or a broken client included, becomes
phase C<Error> with the reason in the C<Ready> condition. Run one step at a
time per Comb. In order:

=over

=item 1. Upstream

Resolved from the first source that I<exists>, whose answer is final even
when it is "local": the L</upstream> constructor argument, C<spec.upstream>
of L</crd> (an explicit C<null> is "local"), a class method C<upstream>;
else local. The coderef and the class method return nothing (local), an
object doing L<Kubernetes::Comb::Role::Upstream>, C<< Name => (%args) >>
for C<< Kubernetes::Comb::Upstream::Name->new(%args) >>, or
C<< '+Full::Class' => (%args) >> for that class -- or a Future of that. The
custom resource and a hashref say C<< { class => 'Full::Class', %args } >>,
the class always fully qualified. An answer that does not resolve is an
C<Error>.

=item 2. Enabled

C<spec.enabled> false, or unset while the class is L</optional>:
C<Disabled>. A disabled Comb touches no resource -- what runs keeps running.

=item 3. Dependencies

Each of L</depends_on> goes to the L</resolver> as written (C<name> or
C<namespace/name>), with the Comb as second argument; it returns the Comb
instance or C<undef>. One not found, one whose L</healthy> is false or
fails, a dying resolver, or none at all: C<Blocked>, every problem in the
message.

=item 4. Check

L</check> reports missing prerequisites: C<NeedsConfig>.

=item 5a. Local

Without an upstream. L</status> healthy, every resource applied as it is
rendered now, and C<managedResources> naming just what the manifests
render: C<Running>, nothing applied.

Not healthy: L</deploy>, then prune: every namespaced resource this Comb
recorded in C<managedResources> that it no longer renders -- compared by
group, kind, namespace and name, so a new API version is no orphan -- is
deleted if it still carries L</label_selector>, name and namespace of this
Comb, together with what it owns (C<propagationPolicy> C<Background>: the
Pods of a Job, the ReplicaSets of a Deployment). One that does not -- it
lost the labels, or a same-named Comb of another namespace applied it last
-- is left alone and dropped from the record, one that is gone is dropped,
one that fails to delete stays for the next step. A cluster-scoped one is
never deleted: a Namespace or a CustomResourceDefinition takes far more with
it, and a same-named Comb of another namespace may render it too. It is
dropped from the record and left in place, which the C<Ready> message
says. Then C<Pending>. A deploy that fails half-way is an C<Error> that
records what it applied on top of the previous record, and prunes nothing.

Healthy, but a resource was applied from another manifest than the one
rendered now -- a new image in the class, a changed C<spec.config> the
manifests render from: deploy and prune all the same, then C<Pending>, the
C<Ready> message naming the resources; the next step finds the Comb
C<Running>, or not. The live L</applied_digest_annotation> tells, compared
with the digest of the rendered manifest (see L</deploy>). A resource that
carries none -- applied by a version before there was one -- counts as
changed, which deploys the Comb once. What is compared is what the Comb
renders, never the live object: a change made to that by hand is not
detected, and a rolling L</restart> is no change. Two kinds of resources
never deploy a Comb by their digest, since a deploy would not change them
and so every step would deploy:

=over

=item * What the client does not replace once it exists (see
L<Kubernetes::Comb::Role::Client/ensure>): a C<v1> PersistentVolumeClaim,
and a C<batch/v1> Job that runs or has succeeded. They keep the digest they
were created with. A Job that failed makes the Comb unhealthy, so it is
deployed, which replaces the Job by what is rendered now.

=item * What a same-named Comb of another namespace applied last -- it
carries that Comb's L</comb_namespace_label>, and that Comb's digest.

=back

Healthy and applied as rendered, but the record names other resources than
the manifests render -- one dropped from the manifests, a delete that
failed, one that runs but was never recorded: deploy and prune all the
same, and stay C<Running>, the C<Ready> message saying so. Everything the
manifests render was live and healthy before.

A workload scaled below its manifest counts as not healthy (see
L</status>), so a reconcile after L</stop>, or after scaling a Deployment
down by hand, deploys again, which scales the workloads back up. The first
step after borrowing from an upstream deploys even when L</status> looks
healthy, since the bridge may stand where the local resources belong.

=item 5b. Upstream

With an active upstream (see L<Kubernetes::Comb::Role::Upstream>), the Comb
runs nothing of its own and borrows the service instead:

=over

=item * The upstream's C<status>. Not reachable: C<Blocked> with its
message. A C<via> of more than L</max_upstream_depth> layers is taken for a
loop: C<Blocked> (C<UpstreamLoop>), the recorded C<via> cut to that length.

=item * The upstream's C<endpoints>, matched by name to L</endpoints>: each
declared endpoint gets the upstream's C<cluster> address (else its
C<external> one) and C<external> -- the redirected endpoints, which
L</endpoint> returns and C<status.endpoints> publishes. One the upstream has
no address for: C<Blocked>.

=item * L</bridge_manifests> for the redirected endpoints. A bridge that
cannot be: C<Blocked>, nothing deployed.

=item * C<replicate_into>, when the upstream has it. A failure: C<Error>.

=item * The bridge is deployed and pruned as the manifests are in the local
path, so the local workloads go and a local Service of a bridged name is
changed in place. Then C<Running> when the upstream is C<Running>, else
C<Pending> with its phase.

=back

A failing C<status> or C<endpoints>, an answer that is none, or a bridge that
does not render: C<Error>. Whatever the upstream's C<status> said is
recorded in C<status.upstream>.

=item 6. Record

Phase, conditions, the resolved endpoints -- the redirected ones while
borrowing, once they are known --, C<status.upstream> while an upstream is
active, C<managedResources> and C<observedGeneration> go through
C<update_status> into L</crd>, which is replaced by what the API server
returns; without a custom resource the status is kept in memory. A failed
write is retried once on a freshly read custom resource; if that fails too
the status is kept in memory and carries a C<StatusWritten> condition that
says why.

A step that changes nothing that serves carries C<managedResources>, the
endpoints and C<status.upstream> of the previous status forward: one that
stops before step 5 (C<Disabled>, C<Blocked> by its dependencies,
C<NeedsConfig>, an C<Error> there), and a local step that fails before it is
through. So a bridge stays recorded -- and replaced by the next local step
-- until the local path has deployed in its place; C<status.upstream> goes
once it has. On the very first step there is nothing to carry, and a local
Comb publishes its own endpoints. The upstream path records what its
upstream says now, and endpoints only once the upstream offers an address
for each.

=back

Conditions: C<Ready> (C<True> when C<Running>; its reason and message are
the step's), C<DependenciesReady> and C<ConfigReady> (each C<Unknown> with
reason C<NotChecked> when the step did not get that far), and
C<StatusWritten> -- present only when writing the status failed (see step
6), C<False> with the reason. Their C<lastTransitionTime> changes only when
their status does.

=head2 deploy

  my @stored = $comb->deploy->get;

Renders L</manifests>, labels every resource (and the Pod templates of
workloads) with L</comb_labels>, puts L</namespace> on namespaced resources
that name none and L</applied_digest_annotation> on every one, and creates
or updates them one after the other. Future of
the objects as stored. A failure stops at that resource; the Future fails
with the message, category C<deploy> and C<< { applied => [...], failed => $manifest } >>.
Manifests that do not render fail it with category C<manifests>.

An update replaces the object with what the manifest says, so the Pod
template of a live Deployment, StatefulSet or DaemonSet would lose the
L</restart_annotation> L</restart> put there -- rolling its Pods once more,
or undoing a restart under way. Deploy keeps it: the rendered Pod template
gets the live value. It reads those workloads first, one list by
L</comb_label> per kind (L</reconcile> passes on what it has read anyway);
when that fails, so does the deploy -- category C<deploy>, nothing applied.

The L</applied_digest_annotation> holds C<sha256:> and the SHA-256, in hex,
of the manifest as it is applied -- what the class rendered, with the
labels, the namespace and the C<apiVersion> deploy adds -- but for that
annotation itself and the restart annotation carried over. It is taken of
the canonical JSON of the manifest with every number and string as a
string, so it does not depend on how Perl holds a value: C<replicas: 2> and
C<replicas: "2"> digest alike. A manifest holding what is no data (a code
reference, an object without C<TO_JSON>) does not render. L</reconcile>
compares the digest; the bridge of a borrowing Comb carries one too, which
nothing compares.

=head2 status

  my $status = $comb->status->get;

Future of what the cluster shows of the Comb right now:

  {
    phase   => 'Running',   # Running, Pending, Error, Stopped or NotDeployed
    healthy => 1,
    reason  => '...',       # when there is a problem: the first one's reason
    message => '...',       # every problem, joined with '; '
    pods    => [ { name, phase, ready, restarts, reason, message }, ... ]
  }

It looks for every rendered resource (by L</comb_label> alone: where a
same-named Comb of another namespace renders the same resource, the one that
applied it last owns it, and both find it) and at the Pods of the Comb (by
L</label_selector>). C<NotDeployed>: none of the resources exists.
C<Stopped>: as L</stop> leaves the Comb -- every Deployment and StatefulSet
at 0 replicas, every CronJob suspended, at least one of them against its
manifest. What stop leaves running (a DaemonSet, a ReplicaSet, a bare Pod)
does not keep a Comb from C<Stopped>; a manifest that says C<replicas: 0> or
C<suspend: true> itself is at rest as rendered, not stopped.
C<Running>: every resource exists, every Pod that should run has all its
containers ready, the replicated workloads have their ready replicas and the
Jobs completed. A replicated workload wants the replicas of its manifest
(default 1, what L</deploy> sets); scaled below that, by hand or by
L</stop>, it is short of them (C<ReplicasNotReady>, "scaled to" in the
message), scaled beyond it -- by hand, by an autoscaler -- it wants its
scale. A Comb without workloads is running once its resources
exist. Waiting and terminated container reasons, restart counts and
C<PodScheduled=False> make up the reasons and messages; a reason that does not
pass by waiting (C<CrashLoopBackOff>, C<ImagePullBackOff>, a failed Job, a
failed Pod of its own) makes the phase C<Error>. Completed Pods never count
against the Comb; a failed Pod that belongs to a controller is left to it.

With an active upstream (resolved as in L</reconcile>) the Comb runs no
Pods; the status is that of the borrowed service instead, with C<pods> empty
and an C<upstream> key holding what C<status.upstream> would. C<Running>:
the upstream is reachable and C<Running> and every resource of the bridge
(L</bridge_manifests>) exists. C<Pending> or C<NotDeployed> while that is
not so; C<Blocked> or C<Error> where L</reconcile> would stop with that
phase.

=head2 healthy

Future of a boolean: whether L</status> is C<Running>.

=head2 logs

  print $comb->logs(lines => 50)->get;

Future of the last C<lines> (default 100) log lines of every container of the
Comb's Pods. With more than one container, each gets a C<==E<gt> pod/container
E<lt>==> header. A container in C<CrashLoopBackOff> shows its previous
instance, marked C<(previous)>. A container whose log cannot be read shows why
instead of failing the whole Future.

=head2 restart

Rolling restart: sets L</restart_annotation> to the current time (RFC 3339)
on the Pod template of every Deployment, StatefulSet and DaemonSet of the
Comb; deletes its Jobs together with their Pods. Future of the list of what
it touched, as C<Kind/name>. L</deploy> -- and so L</reconcile> -- keeps the
annotation.

=head2 stop

Scales the Deployments and StatefulSets of the Comb to 0, suspends its
CronJobs and deletes its Jobs together with their Pods. Future of the list
of what it touched, as C<Kind/name>. L</status> is C<Stopped> then; the next
L</reconcile> deploys the Comb again.

=head2 describe

Future of a hashref with everything about the Comb, plain data:
C<name>, C<class>, C<namespace>, C<depends_on>, C<endpoints> (resolved, as
hashrefs), C<status> (see L</status>), C<recorded> (the L</recorded_status>,
when there is one) and C<stub_of> (class of the original, for a stub).

=head2 endpoint

  my $ep = $comb->endpoint('client')->get;

Future of the L<Kubernetes::Comb::Endpoint> of that name, with its resolved
addresses. Fails for a name the Comb does not offer. With an active upstream
the addresses are the redirected ones (see L</reconcile>), and it fails with
the reason when the upstream offers none.

=head2 recorded_status

The status the Comb last recorded, a L<Kubernetes::Comb::CRD::CombStatus>
or C<undef>: C<status> of L</crd>, without a custom resource the one kept in
memory. Unlike L</status> this reads nothing from the cluster.

=head1 SEE ALSO

=over

=item * L<Kubernetes::Comb::CRD::Comb> -- the custom resource

=item * L<Kubernetes::Comb::Role::Client> -- the client surface

=item * L<Kubernetes::Comb::Endpoint>

=item * L<Kubernetes::Comb::Role::Upstream>, L<Kubernetes::Comb::Upstream::K8s>,
L<Kubernetes::Comb::Upstream::Static> -- layering

=item * L<Kubernetes::Comb::Static> -- a Comb whose manifests are files

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-kubernetes-comb/issues>.

=head2 IRC

Join C<#kubernetes> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
