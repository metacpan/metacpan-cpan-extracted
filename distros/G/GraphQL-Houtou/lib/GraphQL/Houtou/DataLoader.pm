package GraphQL::Houtou::DataLoader;

use 5.014;
use strict;
use warnings;

use Promise::XS ();
# The Houtou XS runtime resolves promise continuations through helpers in
# this module; settling loader promises requires it to be loaded.
use GraphQL::Houtou::Promise::PromiseXS ();
use Scalar::Util qw(blessed);

our $VERSION = '0.03';

# Reference batching loader for GraphQL::Houtou, following the semantics of
# Facebook's dataloader. It is written strictly against the public batching
# contract (execute's on_stall hook): loads queue a key and return a
# Promise::XS promise; dispatch() sends every queued key to the batch
# function in one call and settles the promises. It never touches executor
# internals, so alternative loader implementations are equally supported.

sub new {
  my ($class, %args) = @_;
  my $batch = $args{batch};
  die "GraphQL::Houtou::DataLoader requires a 'batch' function\n"
    if ref($batch) ne 'CODE';
  return bless {
    batch => $batch,
    max_batch_size => $args{max_batch_size} || 0,
    cache => exists $args{cache} ? ($args{cache} ? 1 : 0) : 1,
    cache_key => ref($args{cache_key}) eq 'CODE' ? $args{cache_key} : sub { $_[0] },
    _promises => {},
    _queue => [],
  }, $class;
}

sub load {
  my ($self, $key) = @_;
  die "GraphQL::Houtou::DataLoader::load requires a defined key\n" if !defined $key;
  my $cache_key = $self->{cache_key}->($key);
  if ($self->{cache} && exists $self->{_promises}{$cache_key}) {
    return $self->{_promises}{$cache_key};
  }
  my $deferred = Promise::XS::deferred();
  push @{ $self->{_queue} }, [ $key, $deferred ];
  my $promise = $deferred->promise;
  $self->{_promises}{$cache_key} = $promise if $self->{cache};
  return $promise;
}

# dataloader-js semantics: takes an arrayref of keys, returns one promise
# that resolves with an arrayref of values in key order. Per-key failures
# do not reject the promise; the failed slots hold
# GraphQL::Houtou::DataLoader::Error objects instead.
sub load_many {
  my ($self, @args) = @_;
  if (@args != 1 || ref($args[0]) ne 'ARRAY') {
    warnings::warnif(deprecated =>
      'GraphQL::Houtou::DataLoader::load_many(LIST) is deprecated; '
      . 'pass an arrayref of keys to get a single promise');
    return map { $self->load($_) } @args;
  }
  my $keys = $args[0];
  return Promise::XS::resolved([]) if !@$keys;

  my @results;
  my $remaining = @$keys;
  my $deferred = Promise::XS::deferred();
  for my $i (0 .. $#$keys) {
    my $slot = $i;
    $self->load($keys->[$slot])->then(
      sub {
        $results[$slot] = $_[0];
        $deferred->resolve(\@results) if !--$remaining;
        return;
      },
      sub {
        my ($reason) = @_;
        $results[$slot] =
          blessed($reason) && $reason->isa('GraphQL::Houtou::DataLoader::Error')
          ? $reason
          : GraphQL::Houtou::DataLoader::Error->new($reason);
        $deferred->resolve(\@results) if !--$remaining;
        return;
      },
    );
  }
  return $deferred->promise;
}

sub prime {
  my ($self, $key, $value) = @_;
  my $cache_key = $self->{cache_key}->($key);
  return $self if !$self->{cache} || exists $self->{_promises}{$cache_key};
  $self->{_promises}{$cache_key} = Promise::XS::resolved($value);
  return $self;
}

sub clear {
  my ($self, $key) = @_;
  delete $self->{_promises}{ $self->{cache_key}->($key) };
  return $self;
}

sub clear_all {
  my ($self) = @_;
  $self->{_promises} = {};
  return $self;
}

sub pending_count { return scalar @{ $_[0]{_queue} } }

# Send every queued key to the batch function and settle the promises.
# Returns the number of keys dispatched (the on_stall progress signal).
# Settling promises runs GraphQL continuations synchronously, which may
# queue new loads; those land in a fresh queue for the next dispatch.
sub dispatch {
  my ($self) = @_;
  my $queue = $self->{_queue};
  return 0 if !@$queue;
  $self->{_queue} = [];

  my $dispatched = 0;
  my $max = $self->{max_batch_size};
  while (@$queue) {
    my @chunk = splice(@$queue, 0, ($max > 0 && $max < @$queue) ? $max : scalar @$queue);
    my @keys = map { $_->[0] } @chunk;
    my $values = eval { $self->{batch}->(\@keys) };
    my $batch_error = $@;

    if ($batch_error || ref($values) ne 'ARRAY' || @$values != @keys) {
      my $reason = $batch_error
        || "DataLoader batch function must return an arrayref with one entry per key\n";
      for my $entry (@chunk) {
        $entry->[1]->reject($reason);
        $dispatched++;
      }
      next;
    }

    for my $i (0 .. $#chunk) {
      my $value = $values->[$i];
      if (blessed($value) && $value->isa('GraphQL::Houtou::DataLoader::Error')) {
        $chunk[$i][1]->reject($value->message);
      } else {
        $chunk[$i][1]->resolve($value);
      }
      $dispatched++;
    }
  }
  return $dispatched;
}

# Build an on_stall callback that keeps dispatching a set of loaders until
# a full pass makes no progress. Loaders may feed each other: settling one
# loader's promises can queue loads on another within the same stall.
sub on_stall_for {
  my ($class, @loaders) = @_;
  return sub {
    my $total = 0;
    my $round;
    do {
      $round = 0;
      $round += $_->dispatch for @loaders;
      $total += $round;
    } while ($round);
    return $total;
  };
}

package GraphQL::Houtou::DataLoader::Error;

sub new {
  my ($class, $message) = @_;
  return bless { message => $message }, $class;
}

sub message { return $_[0]{message} }

package GraphQL::Houtou::DataLoader;

1;
__END__

=encoding utf-8

=head1 NAME

GraphQL::Houtou::DataLoader - batching loader for GraphQL::Houtou resolvers

=head1 SYNOPSIS

  use GraphQL::Houtou qw(execute);
  use GraphQL::Houtou::DataLoader;

  # per request
  my $users = GraphQL::Houtou::DataLoader->new(batch => sub {
    my ($ids) = @_;
    my %row = map { $_->{id} => $_ } $db->select_users_in(@$ids);
    return [ map { $row{$_} } @$ids ];   # one entry per key, key order
  });

  # resolvers return promises from the loader
  #   resolve => sub { my ($src) = @_; $users->load($src->{user_id}) }

  my $result = execute($schema, $query, $variables,
    context => { users => $users },
    on_stall => GraphQL::Houtou::DataLoader->on_stall_for($users),
  );

=head1 DESCRIPTION

Solves the N+1 problem for SQL-backed resolvers. Every C<load> during one
execution phase queues its key and returns a promise; when execution stalls
(all remaining fields are waiting on promises), the C<on_stall> hook
dispatches the queued keys to the batch function in a single call and
settles the promises, which resumes execution. A query touching N users
issues one batched lookup per nesting level instead of N individual ones.

C<execute> with C<on_stall> drives the request to completion and returns
the finished response synchronously - callers never handle promises.

=head1 MULTIPLE LOADERS

Real schemas use several loaders per request, and one loader is usually
shared by every field that resolves the same kind of record. Both shapes
need no special wiring: put every loader in the context and register them
all with C<on_stall_for>:

  my $users   = GraphQL::Houtou::DataLoader->new(batch => \&batch_users);
  my $entries = GraphQL::Houtou::DataLoader->new(batch => \&batch_entries);

  # Blog.author and Entry.author share $users; Blog also uses $entries.
  #   Blog:  author      => sub { $_[2]->{users}->load($_[0]{author_id}) }
  #          latestEntry => sub { $_[2]->{entries}->load($_[0]{latest_entry_id}) }
  #   Entry: author      => sub { $_[2]->{users}->load($_[0]{author_id}) }

  my $result = execute($schema, $query, $variables,
    context  => { users => $users, entries => $entries },
    on_stall => GraphQL::Houtou::DataLoader->on_stall_for($users, $entries),
  );

Sharing one loader across types means the per-request cache dedupes keys
globally: a user already fetched for C<Blog.author> is not fetched again
for C<Entry.author>. Loaders may also feed each other - settling one
loader's promises can queue loads on another, and a single stall keeps
dispatching until a full pass makes no progress - so each dependency
level still costs one batched query per loader.

=head1 THE BATCH FUNCTION

Receives an arrayref of unique keys and must return an arrayref of the
same length, in key order. An entry may be a
C<GraphQL::Houtou::DataLoader::Error> object to fail only that key; a die
inside the batch function fails every key in the batch.

=head1 METHODS

C<load($key)>, C<load_many(\@keys)>, C<prime($key, $value)>, C<clear($key)>,
C<clear_all>, C<pending_count>, C<dispatch>.

C<load_many> follows dataloader-js C<loadMany>: it takes an arrayref of
keys and returns a single promise that resolves with an arrayref of values
in key order. It never rejects on per-key failures - failed slots hold
C<GraphQL::Houtou::DataLoader::Error> objects (check with C<blessed> +
C<isa>, read the reason with C<< ->message >>). Calling it with a flat key
list is deprecated (it returns one promise per key and warns in the
C<deprecated> category).

Instances cache per key (create one loader per request unless you want
cross-request caching). Pass C<< cache => 0 >> to disable, C<cache_key>
to derive cache keys from structured keys, C<max_batch_size> to chunk
large batches.

=head1 THE on_stall CONTRACT

This loader is one implementation of the generic batching contract: the
C<on_stall> callback passed to C<execute> is invoked whenever execution
cannot proceed because promises are pending, and must return the number of
units it dispatched. Returning 0 while promises remain pending is reported
as a deadlock. Anything that can resolve promises - a hand-written batcher,
an ORM-specific loader - can implement the same contract;
C<< GraphQL::Houtou::DataLoader->on_stall_for(@loaders) >> builds the
callback for one or more of these loaders.

=cut
