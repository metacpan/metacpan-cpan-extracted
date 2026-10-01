#!/usr/bin/env perl
# Drives the Combs of one namespace on an IO::Async loop: examples/sync.pl,
# asynchronously. See the POD at the end, or run it with --help.
use strict;
use warnings;
use feature qw( say );

use FindBin qw( $Bin );
use lib $Bin.'/lib', $Bin.'/../lib';   # the example Comb classes, this Kubernetes::Comb

use Future;
use Future::AsyncAwait;
use Getopt::Long qw( GetOptions );
use IO::Async::Loop;
use Path::Tiny qw( path );
use POSIX qw( strftime );
use Pod::Usage qw( pod2usage );
use Kubernetes::Comb;
use Kubernetes::Comb::Client::Async;   # dies naming IO::Async or Net::Async::Kubernetes if missing or too old

my %opt = (
  namespace  => 'comb-demo',
  db_address => 'postgres.shared.svc:5432',
  env_file   => 'combs.env',
  interval   => 5,
  rounds     => 0
);
GetOptions( \%opt,
  'context=s',
  'namespace=s',
  'upstream_context|upstream-context=s',
  'db_address|db-address=s',
  'env_file|env-file=s',
  'interval=i',
  'rounds=i',
  'help'
) or pod2usage(2);
pod2usage(1) if $opt{help};

# One client for all Combs, on the loop. Its Futures complete while the loop
# runs; an upstream in another context gets its own client on the same loop.
my $loop = IO::Async::Loop->new;
my $k8s  = Kubernetes::Comb::Client::Async->new(
  loop => $loop,
  ( $opt{context} ? ( context => $opt{context} ) : () )
);

# The layers: where a Comb borrows its service from instead of running it.
# db borrows -- from its peer Comb in another kube context, or from a fixed
# address. A Comb without an entry gets no upstream option, so its custom
# resource or its class decides; a Comb given one gets the coderef's answer,
# and that answer is final.
my %upstream = (
  db => $opt{upstream_context}
    ? sub { K8s => ( context => $opt{upstream_context} ) }
    : sub {
        Static => (
          endpoints => [ { name => 'postgres', port => 5432, cluster => $opt{db_address} } ],
          via       => [ 'static' ]
        );
      }
);

# The stubs: mailer runs as its stub class (Example::Comb::Mailer::Stub, the
# default stub_class of Example::Comb::Mailer).
my %stub = ( mailer => 1 );

my %comb;               # namespace/name => the Comb instance
my %built;              # namespace/name => uid/generation it was built from
my %state;              # namespace/name => the state last reported
my $cycles = '';        # the dependency cycles last reported

# The only way a Comb finds its dependencies: name or namespace/name.
my $resolver = sub {
  my ( $ref, $comb ) = @_;
  return $comb{ key_of( $ref, $comb->namespace ) };
};

# The rounds, as one Future. Between the awaits the loop is free: this is
# where a watch on the Comb resources, a status page or a signal handler
# would join it.
async sub manage {
  my $round = 0;
  while ( !$opt{rounds} || $round < $opt{rounds} ) {
    await $loop->delay_future( after => $opt{interval} ) if $round++;   # between rounds

    # 1. The Comb custom resources. A manager could watch them instead.
    my $list = await $k8s->list( 'Comb', namespace => $opt{namespace} )->else( sub {
      say stamp().' listing the Comb resources failed: '.( $_[0] =~ s/\s+\z//r );
      return Future->done;
    } );

    # 2. An instance for each that is new or changed.
    refresh( $list->items // [] ) if $list;

    # 3. and 4. One step each, dependencies first. reconcile never fails:
    # whatever goes wrong is the phase Error, with the reason.
    for my $comb ( in_dependency_order() ) {
      my $status = await $comb->reconcile;
      my ( $ready ) = grep { $_->type eq 'Ready' } @{ $status->conditions // [] };
      report( key_of( $comb->name, $comb->namespace ), $status->phase, $ready ? ( $ready->reason, $ready->message ) : () );
    }

    # For Docker and plain processes next to the cluster.
    write_env_file();
  }
}

$loop->await( manage() )->get;

####
#### The manager's chores
####

sub key_of {
  my ( $ref, $namespace ) = @_;
  return $ref =~ m{/} ? $ref : $namespace.'/'.$ref;
}

# Builds a Comb for each custom resource that is new or whose spec changed
# (its generation), and forgets those that are gone -- their resources stay
# in the cluster. A resource that does not build is reported and tried again
# when it changes.
sub refresh {
  my ( $crs ) = @_;
  my %listed;
  for my $cr (@$crs) {
    my $meta    = $cr->metadata;
    my $key     = key_of( $meta->name, $meta->namespace );
    my $version = join '/', $meta->uid // '', $meta->generation // 0;
    $listed{$key} = 1;
    next if defined $built{$key} && $built{$key} eq $version;
    $built{$key} = $version;
    my $comb = eval {
      Kubernetes::Comb->from_crd( $cr,
        k8s      => $k8s,
        resolver => $resolver,
        stub     => sub { my ( $comb ) = @_; $stub{ $comb->name } },
        ( $upstream{ $meta->name } ? ( upstream => $upstream{ $meta->name } ) : () )
      );
    };
    unless ($comb) {
      delete $comb{$key};
      report( $key, 'NotBuilt', undef, $@ =~ s/\s+\z//r );
      next;
    }
    $comb{$key} = $comb;
    say stamp().' '.$key.': built as '.ref($comb).( $comb->is_stub ? ', the stub of '.ref( $comb->stub_of ) : '' );
  }
  for my $key ( grep { !$listed{$_} } sort keys %built ) {
    delete $comb{$key};
    delete $built{$key};
    report( $key, 'Removed' );
    delete $state{$key};
  }
}

# The Combs, each after those it depends on: a depth-first topological
# sort. A cycle is reported, and its Combs are reconciled all the same --
# each waits for the other to be healthy, so they stay Blocked and say why
# in their status.
sub in_dependency_order {
  my ( %mark, @order, @found );
  visit( $_, [], \%mark, \@order, \@found ) for sort keys %comb;
  my $text = join '; ', map { join ' -> ', @$_ } @found;
  say stamp().' dependency cycle: '.$text.' (these stay Blocked)' if length $text && $text ne $cycles;
  $cycles = $text;
  return @comb{@order};
}

sub visit {
  my ( $key, $path, $mark, $order, $found ) = @_;
  my $mark_of = $mark->{$key} // '';
  return if $mark_of eq 'done';
  if ( $mark_of eq 'visiting' ) {
    my ( $from ) = grep { $path->[$_] eq $key } 0 .. $#$path;
    push @$found, [ @{$path}[ $from .. $#$path ], $key ];
    return;
  }
  $mark->{$key} = 'visiting';
  my $comb = $comb{$key};
  # A dependency that is not one of ours is no edge: the resolver does not
  # find it, and the Comb goes Blocked on it.
  visit( $_, [ @$path, $key ], $mark, $order, $found )
    for grep { $comb{$_} } map { key_of( $_, $comb->namespace ) } $comb->depends_on;
  $mark->{$key} = 'done';
  push @$order, $key;
}

# Prints a line when the state of a Comb -- phase and reason -- changes.
sub report {
  my ( $key, $phase, $reason, $message ) = @_;
  my $now = $phase.( defined $reason ? ' ('.$reason.')' : '' );
  return if defined $state{$key} && $state{$key} eq $now;
  say stamp().' '.$key.': '.( $state{$key} // 'new' ).' -> '.$now
    .( defined $message && length $message ? ': '.$message : '' );
  $state{$key} = $now;
}

# The endpoints every Comb published with its status (status.endpoints):
# resolved, so the upstream's addresses where it borrows. For one endpoint
# known by name, $comb->endpoint($name) gives the same.
sub write_env_file {
  my @lines = ( '# Endpoints of the Combs in '.$opt{namespace}.', written by '.path($0)->basename );
  for my $comb ( map { $comb{$_} } sort keys %comb ) {
    my $status = $comb->recorded_status or next;
    push @lines, '# '.$comb->name.': '.$status->phase;
    for my $endpoint ( @{ $status->endpoints // [] } ) {
      my $var = uc( $comb->name.'_'.$endpoint->name ) =~ s/[^A-Z0-9]+/_/gr;
      push @lines, $var.'_CLUSTER='.$endpoint->cluster   if defined $endpoint->cluster;
      push @lines, $var.'_EXTERNAL='.$endpoint->external if defined $endpoint->external;
    }
  }
  my $text = join '', map { $_."\n" } @lines;
  my $file = path( $opt{env_file} );
  return if $file->is_file && $file->slurp_utf8 eq $text;
  $file->spew_utf8($text);
  say stamp().' wrote '.$file;
}

sub stamp { strftime( '%H:%M:%S', localtime ) }

__END__

=head1 NAME

async.pl - drive the Combs of a namespace on an IO::Async loop

=head1 SYNOPSIS

  # once: the CustomResourceDefinition, a namespace, the three Combs
  perl -Ilib -MKubernetes::Comb::CRD::Comb \
    -e 'print Kubernetes::Comb::CRD::Comb->to_crd->to_yaml' | kubectl apply -f -
  kubectl create namespace comb-demo
  kubectl apply -n comb-demo -f examples/combs.yaml

  # db borrowed from a fixed address, or from its peer in context dev
  perl examples/async.pl
  perl examples/async.pl --upstream-context dev

=head1 OPTIONS

  --context NAME           kube context to manage, default the current one
  --namespace NAME         namespace of the Combs, default comb-demo
  --upstream-context NAME  db borrows from its peer Comb in this context
                           (Kubernetes::Comb::Upstream::K8s)
  --db-address HOST:PORT   else db borrows from this address
                           (Kubernetes::Comb::Upstream::Static),
                           default postgres.shared.svc:5432
  --env-file PATH          where the endpoints go, default combs.env
  --interval SECONDS       pause between rounds, default 5
  --rounds N               stop after N rounds, default 0: never
  --help

=head1 DESCRIPTION

The manager of F<sync.pl>, line for line, on an L<IO::Async> loop with
L<Kubernetes::Comb::Client::Async>: every C<< ->get >> there is an C<await>
here, C<sleep> is C<delay_future>. The Combs are the same objects either
way -- every lifecycle method returns a L<Future>, and only the client
decides whether it is done at once or when the loop gets to it.
Kubernetes::Comb itself uses no C<async sub>; this script does, which is why
it needs L<Future::AsyncAwait>, and L<IO::Async> and
L<Net::Async::Kubernetes> for the client. Those are optional dependencies of
Kubernetes::Comb.

Each round it does what a manager must do:

=over

=item 1. List the C<Comb> custom resources of the namespace.

=item 2. Build an instance for each that is new or changed, with
C<< Kubernetes::Comb->from_crd($cr, %opts) >>: C<k8s> the client,
C<resolver> the lookup of dependencies among them, C<upstream> for the
Combs that borrow, C<stub> for those that run as their stub.

=item 3. Order them by C<depends_on>, dependencies first, and report
dependency cycles.

=item 4. C<reconcile> each: one step, a Future of the new status, written
into the custom resource by the Comb itself. Every change of phase or
reason is printed.

=back

After each round the endpoints the Combs published go into an env file,
C<E<lt>COMBE<gt>_E<lt>ENDPOINTE<gt>_CLUSTER> and C<..._EXTERNAL>, for
C<docker run --env-file> and friends. For the three Combs of F<combs.yaml>
see F<sync.pl>.

This mutates the cluster the context points to. Deleting a Comb resource
leaves what it deployed in place: this manager just forgets it.

=head1 SEE ALSO

L<Kubernetes::Comb>, L<Kubernetes::Comb::Client::Async>, F<examples/sync.pl>

=cut
