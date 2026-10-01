package Kubernetes::Comb::Client::Fake;
# In-memory Comb client for the unit tests. Plain POD: t/lib is not woven.

use Moo;
with 'Kubernetes::Comb::Role::Client';

use Carp qw( croak );
use Future;
use IO::K8s;
use IO::K8s::List;
use Scalar::Util qw( blessed );
use Types::Standard qw( HashRef Int Str );
use Kubernetes::Comb::CRD;
use namespace::autoclean;

=head1 SYNOPSIS

  use lib 't/lib';
  use Kubernetes::Comb::Client::Fake;

  my $k8s = Kubernetes::Comb::Client::Fake->new(
    objects => [ $comb_cr, { kind => 'Pod', apiVersion => 'v1', metadata => { ... } } ]
  );

  $k8s->ensure($deployment)->get;                  # stored, and recorded
  my @ensured = map { $_->[0] } $k8s->calls_of('ensure');

  $k8s->fail_on(ensure => 'quota exceeded', times => 1);
  $k8s->set_log(name => 'nats-0', namespace => 'platform', text => "line\n");

  my $dev = Kubernetes::Comb::Client::Fake->new(server_url => 'https://dev:6443');
  my $k8s = Kubernetes::Comb::Client::Fake->new(contexts => { dev => $dev });

=head1 DESCRIPTION

Implements L<Kubernetes::Comb::Role::Client> on an in-memory object store, so
the unit tests run without a cluster. Like L<Kubernetes::Comb::Client::Sync>
every request returns an already-done or already-failed L<Future>, and the
failures read like the real ones (C<Kubernetes API error (get Pod): 404 ...>).

What it models of the API server: objects are stored and handed out as
copies; every write sets a new C<metadata.resourceVersion>; C<status> is
written only through C<update_status>/C<patch_status> -- C<ensure>,
C<update> and C<patch> keep the stored status, the way the server treats a
resource with a status subresource; C<ensure> leaves an existing core/v1
PersistentVolumeClaim and a batch/v1 Job that runs or has succeeded
(C<status.active>, C<status.succeeded>) as they are, and replaces any other
Job by a new one without a status, as C<ensure> of L<Kubernetes::REST> and
L<Net::Async::Kubernetes> does; C<list> filters by namespace and
equality/existence label selectors. C<patch> and C<patch_status> apply a
JSON merge patch (also for the C<strategic> type); C<json> patches are not
supported.

Every call is recorded before anything else happens, failed ones included.

=head1 CONSTRUCTOR ARGUMENTS

=over

=item objects

ArrayRef of objects or manifests (hashrefs with C<kind> and C<apiVersion>) to
start with, stored as given -- status included, see L</add>.

=item server_url

What L</server_url> returns. Default C<https://fake.invalid:6443>.

=item contexts

HashRef of context name to client, returned by L</for_context>.

=item context

What C<context> returns: the name of the kube context, as the real clients
have it when they were given one. Default C<undef>.

=item crd_class

The Comb CR class to resolve C<Comb> to, default
L<Kubernetes::Comb::CRD::Comb>.

=back

=cut

has _server_url => (
  is       => 'ro',
  isa      => Str,
  init_arg => 'server_url',
  default  => 'https://fake.invalid:6443'
);

has contexts => ( is => 'ro', isa => HashRef, default => sub { {} } );

has context => ( is => 'ro', isa => Str, predicate => 1 );

has crd_class => ( is => 'ro', isa => Str, default => 'Kubernetes::Comb::CRD::Comb' );

# Set on the client for_context hands out for a context it does not know.
has missing_context => ( is => 'ro', isa => Str, predicate => 1 );

has io_k8s => ( is => 'lazy' );

sub _build_io_k8s {
  my ( $self ) = @_;
  return IO::K8s->new(
    with => [ Kubernetes::Comb::CRD->new( crd_class => $self->crd_class ) ]
  );
}

has _store    => ( is => 'ro', init_arg => undef, default => sub { {} } );
has _calls    => ( is => 'ro', init_arg => undef, default => sub { [] } );
has _failures => ( is => 'ro', init_arg => undef, default => sub { [] } );
has _logs     => ( is => 'ro', init_arg => undef, default => sub { {} } );
has _version  => ( is => 'rw', isa => Int, init_arg => undef, default => 0 );

sub BUILD {
  my ( $self, $args ) = @_;
  $self->add( @{ $args->{objects} } ) if $args->{objects};
}

####
#### Test side
####

=head1 TEST METHODS

=head2 add

  $k8s->add(@objects_or_manifests);

Stores the objects as they are, C<status> included -- the way to put canned
Pods, Deployments or Comb CRs in place. Replaces an object of the same Kind,
namespace and name. Not recorded as a call. Returns the client.

=cut

sub add {
  my ( $self, @objects ) = @_;
  $self->_put( $self->_object($_) ) for @objects;
  return $self;
}

=head2 object

  my $cr = $k8s->object('Comb', 'nats', namespace => 'platform');

A copy of the stored object, or C<undef>. Synchronous; not recorded.

=cut

sub object {
  my ( $self, $kind, $name, %args ) = @_;
  my $stored = $self->_bucket( $self->_class_of($kind) )->{ $args{namespace} // '' }{$name};
  return $stored ? $self->_copy($stored) : undef;
}

=head2 objects_of

  my @pods = $k8s->objects_of('Pod', namespace => 'platform');

Copies of all stored objects of a Kind, sorted by namespace and name; without
C<namespace> across all of them. Synchronous; not recorded.

=cut

sub objects_of {
  my ( $self, $kind, %args ) = @_;
  my $bucket = $self->_bucket( $self->_class_of($kind) );
  my @namespaces = defined $args{namespace} ? ( $args{namespace} ) : sort keys %$bucket;
  return map {
    my $ns = $bucket->{$_} // {};
    map { $self->_copy( $ns->{$_} ) } sort keys %$ns;
  } @namespaces;
}

=head2 calls

  for my $call (@{ $k8s->calls }) { say $call->{method} }

ArrayRef of every request, in order, as C<< { method => ..., args => [...] } >>.
Objects among the arguments are copies taken at call time.

=head2 calls_of

  my @ensured = map { $_->[0] } $k8s->calls_of('ensure');

The argument lists (arrayrefs) of every call of one method, in order.

=head2 clear_calls

Forgets the recorded calls. Returns the client.

=cut

sub calls { shift->_calls }

sub calls_of {
  my ( $self, $method ) = @_;
  return map { $_->{args} } grep { $_->{method} eq $method } @{ $self->_calls };
}

sub clear_calls {
  my ( $self ) = @_;
  @{ $self->_calls } = ();
  return $self;
}

=head2 fail_on

  $k8s->fail_on(ensure => 'quota exceeded');
  $k8s->fail_on(get => 'Kubernetes API error (get Pod): 403 forbidden', times => 1);
  $k8s->fail_on(delete => 'gone', when => sub { $_[0] eq 'Job' });
  $k8s->fail_on('*' => 'connection refused');

Makes calls of a method (C<*>: any) fail with the given message instead of
doing anything. C<times> limits how often, default unlimited; C<when> gets
the call's arguments and decides whether this call fails. The first matching
rule wins. Returns the client.

=head2 clear_failures

Removes every rule of L</fail_on>. Returns the client.

=cut

sub fail_on {
  my ( $self, $method, $message, %opts ) = @_;
  croak 'fail_on needs a method and a message' unless defined $method && defined $message;
  croak 'fail_on: when must be a coderef' if defined $opts{when} && ref $opts{when} ne 'CODE';
  push @{ $self->_failures }, {
    method  => $method,
    message => $message,
    times   => $opts{times},
    when    => $opts{when}
  };
  return $self;
}

sub clear_failures {
  my ( $self ) = @_;
  @{ $self->_failures } = ();
  return $self;
}

=head2 set_log

  $k8s->set_log(
    name      => 'nats-0',
    namespace => 'platform',
    container => 'nats',     # optional
    previous  => 1,          # optional: the previous container
    text      => "..."
  );

The text L</log> returns for exactly this combination. Returns the client.

=cut

sub set_log {
  my ( $self, %args ) = @_;
  croak 'set_log needs name and text' unless defined $args{name} && defined $args{text};
  $self->_logs->{ $self->_log_key(%args) } = $args{text};
  return $self;
}

####
#### Client surface
####

=head1 CLIENT METHODS

C<get>, C<list>, C<ensure>, C<delete>, C<update>, C<patch>,
C<update_status>, C<patch_status>, C<log>, C<server_url> and C<for_context>
as in L<Kubernetes::Comb::Role::Client>. L</for_context> returns the client
given in L</contexts>; for any other context one whose requests fail with
C<Context not found: E<lt>nameE<gt>> and whose C<server_url> croaks with it.
C<delete> takes C<propagationPolicy> as L<Kubernetes::REST> does; an unknown
value or any other option fails the call.

=cut

sub get           { shift->_request( get           => @_ ) }
sub list          { shift->_request( list          => @_ ) }
sub ensure        { shift->_request( ensure        => @_ ) }
sub delete        { shift->_request( delete        => @_ ) }
sub update        { shift->_request( update        => @_ ) }
sub patch         { shift->_request( patch         => @_ ) }
sub update_status { shift->_request( update_status => @_ ) }
sub patch_status  { shift->_request( patch_status  => @_ ) }
sub log           { shift->_request( log           => @_ ) }

sub server_url {
  my ( $self ) = @_;
  croak 'Context not found: '.$self->missing_context if $self->has_missing_context;
  return $self->_server_url;
}

sub for_context {
  my ( $self, $context ) = @_;
  return $self->contexts->{$context} // ref($self)->new( missing_context => $context );
}

sub _request {
  my ( $self, $method, @args ) = @_;
  push @{ $self->_calls }, {
    method => $method,
    args   => [ map { blessed($_) && $_->can('TO_JSON') ? $self->_copy($_) : $_ } @args ]
  };
  return Future->fail( 'Context not found: '.$self->missing_context )
    if $self->has_missing_context;
  my $failure = $self->_take_failure( $method, @args );
  return Future->fail($failure) if defined $failure;
  my $impl = '_do_'.$method;
  my $result;
  # eval here rather than Future->call: croak then names the test's line
  return eval { $result = $self->$impl(@args); 1 }
    ? Future->done($result)
    : Future->fail($@);
}

sub _take_failure {
  my ( $self, $method, @args ) = @_;
  my $rules = $self->_failures;
  for my $i ( 0 .. $#$rules ) {
    my $rule = $rules->[$i];
    next unless $rule->{method} eq '*' || $rule->{method} eq $method;
    next if $rule->{when} && !$rule->{when}->(@args);
    if ( defined $rule->{times} ) {
      $rule->{times}--;
      splice @$rules, $i, 1 if $rule->{times} <= 0;
    }
    return $rule->{message};
  }
  return;
}

sub _do_get {
  my ( $self, $kind, @rest ) = @_;
  my %args = $self->_name_args( get => @rest );
  my $class = $self->_class_of($kind);
  my $stored = $self->_find( get => $class, $kind, $args{namespace}, $args{name} );
  return $self->_copy($stored);
}

sub _do_list {
  my ( $self, $kind, %args ) = @_;
  croak 'fake client: fieldSelector is not supported' if defined $args{fieldSelector};
  my $class = $self->_class_of($kind);
  my @items = grep {
    !defined $args{labelSelector}
      || $self->_selector_matches( $args{labelSelector}, $_->metadata->labels // {} )
  } $self->objects_of( $kind, namespace => $args{namespace} );
  return IO::K8s::List->new( items => \@items, item_class => $class );
}

sub _do_ensure {
  my ( $self, $given ) = @_;
  my $object = $self->_object($given);
  my ( $meta ) = $self->_meta( ensure => $object );
  my $existing = $self->_bucket( ref $object )->{ $meta->namespace // '' }{ $meta->name };
  return $self->_write( $object, $existing ) unless $existing;
  my $resource = $object->api_version.'/'.$object->kind;
  return $self->_copy($existing) if $resource eq 'v1/PersistentVolumeClaim';
  return $self->_write( $object, $existing ) unless $resource eq 'batch/v1/Job';
  my $status = $existing->TO_JSON->{status} || {};
  return $self->_copy($existing) if $status->{succeeded} || $status->{active};
  return $self->_write( $object, undef );   # deleted and created: a new Job
}

sub _do_update {
  my ( $self, $object ) = @_;
  my $meta = $self->_meta( update => $object );
  my $existing = $self->_find( update => ref $object, $object->kind, $meta->namespace, $meta->name );
  return $self->_write( $self->_copy($object), $existing );
}

sub _do_patch {
  my ( $self, @args ) = @_;
  my ( $existing, $patch ) = $self->_patch_target( patch => @args );
  my %main = %$patch;
  delete $main{status};
  my $merged = $self->_merge_patch( $existing->TO_JSON, \%main );
  return $self->_write( ref($existing)->FROM_HASH($merged), $existing );
}

sub _do_update_status {
  my ( $self, $object ) = @_;
  my $meta = $self->_meta( update_status => $object );
  my $existing = $self->_find( update_status => ref $object, $object->kind, $meta->namespace, $meta->name );
  my $updated = $self->_copy($existing);
  $updated->status( $object->status ? $self->_copy_status($object) : undef );
  return $self->_store_new_version($updated);
}

sub _do_patch_status {
  my ( $self, @args ) = @_;
  my ( $existing, $patch ) = $self->_patch_target( patch_status => @args );
  my $merged = $self->_merge_patch(
    $existing->TO_JSON,
    exists $patch->{status} ? { status => $patch->{status} } : {}
  );
  return $self->_store_new_version( ref($existing)->FROM_HASH($merged) );
}

sub _do_log {
  my ( $self, $kind, @rest ) = @_;
  my %args = $self->_name_args( log => @rest );
  my $text = $self->_logs->{ $self->_log_key(%args) };
  croak 'Kubernetes API error (log '.$kind.'): 404 no log for pod "'.$args{name}.'"'
    .( $args{previous} ? ' (previous)' : '' ) unless defined $text;
  if ( defined $args{tailLines} ) {
    my @lines = split /(?<=\n)/, $text;
    splice @lines, 0, @lines - $args{tailLines} if @lines > $args{tailLines};
    $text = join '', @lines;
  }
  return $text;
}

# As Kubernetes::REST: propagationPolicy is the only option, and only one of
# the values the API server knows -- a misspelt one fails, it is not dropped.
sub _do_delete {
  my ( $self, $target, @rest ) = @_;
  my ( $class, $kind, $namespace, $name, %args );
  if ( blessed $target ) {
    my $meta = $self->_meta( delete => $target );
    ( $class, $kind, $namespace, $name ) = ( ref $target, $target->kind, $meta->namespace, $meta->name );
    croak 'Invalid arguments to delete()' if @rest % 2;
    %args = @rest;
  }
  else {
    %args = $self->_name_args( delete => @rest );
    ( $class, $kind, $namespace, $name ) = ( $self->_class_of($target), $target, $args{namespace}, $args{name} );
    delete @args{qw( name namespace )};
  }
  my $policy = delete $args{propagationPolicy};
  croak 'Unknown argument(s) to delete(): '.join( ', ', sort keys %args ) if %args;
  croak 'Unknown propagationPolicy \''.$policy.'\' for delete() (use: Background, Foreground, Orphan)'
    if defined $policy && $policy !~ /\A(?:Background|Foreground|Orphan)\z/;
  $self->_find( delete => $class, $kind, $namespace, $name );
  delete $self->_bucket($class)->{ $namespace // '' }{$name};
  return 1;
}

####
#### Internals
####

# ensure/update: the stored status stays, as with a status subresource.
sub _write {
  my ( $self, $object, $existing ) = @_;
  $object->status( $existing && $existing->can('status') ? $existing->status : undef )
    if $object->can('status');
  return $self->_store_new_version($object);
}

sub _store_new_version {
  my ( $self, $object ) = @_;
  $self->_version( $self->_version + 1 );
  $object->metadata->resourceVersion( ''.$self->_version );
  $self->_put($object);
  return $self->_copy($object);
}

sub _put {
  my ( $self, $object ) = @_;
  my $meta = $self->_meta( store => $object );
  $self->_bucket( ref $object )->{ $meta->namespace // '' }{ $meta->name } = $self->_copy($object);
}

sub _find {
  my ( $self, $op, $class, $kind, $namespace, $name ) = @_;
  my $stored = $self->_bucket($class)->{ $namespace // '' }{$name};
  croak 'Kubernetes API error ('.$op.' '.$kind.'): 404 '.$class->kind.' "'.$name.'" not found'
    unless $stored;
  return $stored;
}

sub _bucket {
  my ( $self, $class ) = @_;
  return $self->_store->{ $class->api_version.'/'.$class->kind } //= {};
}

sub _class_of {
  my ( $self, $kind ) = @_;
  my $class = $self->io_k8s->expand_class($kind);
  croak 'fake client: unknown resource '.$kind
    unless defined $class && eval { $self->io_k8s->load_class($class); $class->api_version };
  return $class;
}

sub _object {
  my ( $self, $given ) = @_;
  return $self->_copy($given) if blessed $given;
  croak 'fake client: a manifest needs kind' unless ref $given eq 'HASH' && $given->{kind};
  return $self->io_k8s->inflate($given);
}

sub _meta {
  my ( $self, $op, $object ) = @_;
  my $meta = $object->metadata;
  croak $op.': object must have metadata.name' unless $meta && $meta->name;
  return $meta;
}

sub _copy {
  my ( $self, $object ) = @_;
  return ref($object)->FROM_HASH( $object->TO_JSON );
}

sub _copy_status {
  my ( $self, $object ) = @_;
  return $self->_copy($object)->status;
}

sub _name_args {
  my ( $self, $op, @rest ) = @_;
  my %args;
  if ( @rest % 2 ) {
    $args{name} = shift @rest;
    %args = ( %args, @rest );
  }
  else {
    %args = @rest;
  }
  croak 'name required for '.$op unless defined $args{name};
  return %args;
}

sub _patch_target {
  my ( $self, $op, $target, @rest ) = @_;
  my ( $existing, %args );
  if ( blessed $target ) {
    %args = @rest;
    my $meta = $self->_meta( $op => $target );
    $existing = $self->_find( $op, ref $target, $target->kind, $meta->namespace, $meta->name );
  }
  else {
    %args = $self->_name_args( $op => @rest );
    $existing = $self->_find( $op, $self->_class_of($target), $target, $args{namespace}, $args{name} );
  }
  croak $op.' requires \'patch\' parameter' unless ref $args{patch} eq 'HASH';
  croak 'fake client: json patches are not supported' if ( $args{type} // '' ) eq 'json';
  return ( $existing, $args{patch} );
}

# RFC 7386 JSON merge patch: null deletes, objects merge, the rest replaces.
sub _merge_patch {
  my ( $self, $target, $patch ) = @_;
  return $patch unless ref $patch eq 'HASH';
  my %out = ref $target eq 'HASH' ? %$target : ();
  for my $key ( keys %$patch ) {
    if ( defined $patch->{$key} ) {
      $out{$key} = $self->_merge_patch( $out{$key}, $patch->{$key} );
    }
    else {
      delete $out{$key};
    }
  }
  return \%out;
}

sub _selector_matches {
  my ( $self, $selector, $labels ) = @_;
  for my $term ( grep { length } map { s/\A\s+|\s+\z//gr } split /,/, $selector ) {
    if ( $term =~ /\A([^!=\s]+)\s*(!=|==|=)\s*(\S*)\z/ ) {
      my ( $key, $op, $value ) = ( $1, $2, $3 );
      my $matches = defined $labels->{$key} && $labels->{$key} eq $value;
      return 0 if $op eq '!=' ? $matches : !$matches;
    }
    elsif ( $term =~ /\A!(\S+)\z/ ) {
      return 0 if exists $labels->{$1};
    }
    elsif ( $term =~ /\A(\S+)\z/ ) {
      return 0 unless exists $labels->{$1};
    }
    else {
      croak 'fake client: unsupported label selector term \''.$term.'\'';
    }
  }
  return 1;
}

sub _log_key {
  my ( $self, %args ) = @_;
  return join "\0", map { $_ // '' }
    $args{namespace}, $args{name}, $args{container}, ( $args{previous} ? 'previous' : '' );
}

1;
