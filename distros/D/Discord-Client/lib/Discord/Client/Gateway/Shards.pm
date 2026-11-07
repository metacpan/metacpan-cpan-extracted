package Discord::Client::Gateway::Shards;

use v5.26;
use strict;
use warnings;
use Carp qw(croak);
use Future;
use IO::Async::Loop;
use Math::BigInt;
use Scalar::Util qw(weaken);
use Discord::Client::Gateway;
use Discord::Client::Gateway::IdentifyLimiter;
use Discord::Client::REST;
use Discord::Client::Error;

our $VERSION = '0.002';

sub new {
    my ( $class, %args ) = @_;

    # Bound shard creation before constructing shared discovery resources.
    my $count = $args{shards} // 'auto';
    croak 'shards must be auto or a positive integer'
        unless !ref($count) && ( $count eq 'auto' || $count =~ /\A[1-9]\d*\z/ );
    my $loop = $args{loop} // IO::Async::Loop->new;
    my $max = $args{max_shards} // 1024;
    croak 'max_shards must be a positive integer' unless !ref($max) && $max =~ /\A[1-9]\d*\z/;
    my $self = bless {
        args => \%args,
        count => $count,
        loop => $loop,
        shards => {},
        handlers => {},
        dispatch_observers => [],
        state => 'idle',
        max_shards => $max,
        completion => $loop->new_future
    }, $class;

    # All children share one REST client and one Identify budget.
    $self->{rest} = $args{rest} // Discord::Client::REST->new( token => $args{token}, loop => $loop );
    $self->{own_rest} = !$args{rest};
    $self->{limiter} = Discord::Client::Gateway::IdentifyLimiter->new(
        loop => $loop,
        rest => $self->{rest},
        ( exists( $args{clock} ) ? ( clock => $args{clock} ) : () ),
        ( exists( $args{delay} ) ? ( delay => $args{delay} ) : () )
    );
    return $self;
}

sub loop { $_[0]->{loop} }
sub shards { +{ %{ $_[0]->{shards} } } }
sub identify_limiter { $_[0]->{limiter} }
sub completion { $_[0]->{completion} }

sub state {
    my ($self) = @_;

    # Readiness reflects every live child, including temporary reconnects.
    return 'closed' if $self->{closed};
    return 'ready' if keys( %{ $self->{shards} } ) && !grep { $_->state ne 'ready' } values %{ $self->{shards} };
    return $self->{state} eq 'ready' ? 'reconnecting' : $self->{state};
}

sub on {
    my ( $self, $event, $callback ) = @_;
    croak 'Event and callback required'
        unless defined($event)
        && !ref($event)
        && length($event)
        && ref($callback) eq 'CODE';

    # Remember listeners for future children and attach them to existing ones.
    push @{ $self->{handlers}{$event} }, $callback;
    $_->on( $event => $callback ) for values %{ $self->{shards} };
    return $self;
}

# Forward internal state observers to existing and future child connections.
sub _on_dispatch {
    my ( $self, $callback ) = @_;
    croak 'dispatch observer must be a code reference' unless ref($callback) eq 'CODE';

    # Register SDK state observers for both existing and future children.
    push @{ $self->{dispatch_observers} }, $callback;
    $_->_on_dispatch($callback) for values %{ $self->{shards} };
    return $self;
}

sub _failed {
    my ( $self, $message, $category ) = @_;
    my $error = Discord::Client::Error->new( message => $message, category => $category );
    return $self->{loop}->new_future->fail( $message, $category, $error );
}

sub connect {
    my ($self) = @_;

    # Coalesce startup waits and reject attempts to restart a closed manager.
    return $self->_failed( 'Shard manager is closed', 'shutdown' ) if $self->{closed};
    return $self->{loop}->new_future->done($self) if $self->state eq 'ready';
    return $self->{ready} if $self->{ready} && !$self->{ready}->is_ready;
    my $future = $self->{loop}->new_future;
    $self->{ready} = $future;
    $future->on_cancel( sub { $self->close } );

    # During recovery, observe each child until the full group becomes ready again.
    if ( $self->{running} ) {
        my $weak = $self;
        weaken($weak);
        $_->connect->on_ready( sub { $weak->_maybe_ready if $weak && !$weak->{closed} } )
            for values %{ $self->{shards} };
        return $future;
    }

    # Discover metadata before choosing the automatic shard count.
    $self->{running} = 1;
    $self->{state} = 'discovering';
    my $info = $self->{limiter}->info;
    $self->{discovery} = $info;
    $info->on_ready(
        sub {
            delete $self->{discovery};
            return if $self->{closed};
            unless ( $info->is_done ) {
                my $error = $self->_failed( 'Shard discovery failed', 'transport' );
                $self->_fatal($error);
                return;
            }
            my ($metadata) = $info->result;
            $self->_start_shards($metadata);
        }
    );
    return $future;
}

sub _start_shards {
    my ( $self, $metadata ) = @_;

    # Validate the server recommendation against the configured process capacity.
    my $count = $self->{count} eq 'auto' ? $metadata->{shards} : $self->{count};
    unless ( defined($count) && !ref($count) && $count =~ /\A[1-9]\d*\z/ && $count <= $self->{max_shards} ) {
        $self->_fatal( $self->_failed( 'Shard count is invalid or exceeds client capacity', 'request' ) );
        return;
    }
    $self->{total} = 0 + $count;
    $self->{state} = 'connecting';

    # Construct children with explicit shard identities and a shared Identify limiter.
    for my $id ( 0 .. $count - 1 ) {
        my $gateway = eval {
            Discord::Client::Gateway->new(
                %{ $self->{args} },
                loop => $self->{loop},
                rest => $self->{rest},
                shard => [ $id, 0 + $count ],
                identify_limiter => $self->{limiter},
            );
        };
        unless ($gateway) {
            $self->_fatal( $self->_failed( 'Invalid shard configuration', 'request' ) );
            last;
        }
        $self->{shards}{$id} = $gateway;
        $self->_attach_shard($gateway);
        last if $self->{closed};
    }
}

sub _attach_shard {
    my ( $self, $gateway ) = @_;

    # Install state observers and application handlers before opening the child.
    $gateway->_on_dispatch($_) for @{ $self->{dispatch_observers} };
    for my $event ( keys %{ $self->{handlers} } ) {
        $gateway->on( $event => $_ ) for @{ $self->{handlers}{$event} };
    }

    # Child failures stop the group without making children own their manager.
    my $weak = $self;
    weaken($weak);
    $gateway->completion->on_fail(
        sub {
            return unless $weak && !$weak->{closed};
            $weak->_fatal( $weak->{loop}->new_future->fail(@_) );
        }
    );
    $gateway->connect->on_ready(
        sub {
            $weak->_maybe_ready if $weak && !$weak->{closed};
        }
    );
}

sub _maybe_ready {
    my ($self) = @_;

    # Complete startup only when the expected number of children are all ready.
    return
        unless keys( %{ $self->{shards} } ) == ( $self->{total} // -1 )
        && !grep { $_->state ne 'ready' } values %{ $self->{shards} };
    $self->{state} = 'ready';
    my $future = delete $self->{ready};
    $future->done($self) if $future && !$future->is_ready;
}

sub _fatal {
    my ( $self, $failure ) = @_;

    # Publish the failure before shutdown can settle outstanding lifetime observers.
    $self->{ready}->fail( $failure->failure ) if $self->{ready} && !$self->{ready}->is_ready;
    $self->{completion}->fail( $failure->failure ) unless $self->{completion}->is_ready;
    $self->close;
}

sub shard_for_guild {
    my ( $self, $guild_id ) = @_;
    croak 'Shard count is not discovered' unless $self->{total};
    croak 'Invalid guild ID' unless defined($guild_id) && !ref($guild_id) && $guild_id =~ /\A\d{1,20}\z/;

    # Use integer arithmetic so routing also works on Perls with smaller native integers.
    my $id = Math::BigInt->new($guild_id);
    croak 'Guild ID exceeds uint64' if $id->bcmp('18446744073709551615') > 0;
    return $id->brsft(22)->bmod( $self->{total} )->numify;
}

sub send {
    my ( $self, $opcode, $data, %args ) = @_;

    # Resolve the target explicitly; a guild ID takes precedence over a shard ID.
    my ( $id, $error );
    if ( exists $args{guild_id} ) {
        $id = eval { $self->shard_for_guild( $args{guild_id} ) };
        $error = $@;
    }
    else {
        $id = $args{shard_id} // 0;
    }
    return $self->_failed( 'Invalid target shard', 'request' )
        if $error || !defined($id) || ref($id) || $id !~ /\A\d+\z/ || !$self->{shards}{$id};
    return $self->{shards}{$id}->send( $opcode, $data );
}

sub broadcast {
    my ( $self, $opcode, $data ) = @_;
    return $self->_failed( 'Shards are not ready', 'state' ) unless $self->state eq 'ready';
    return Future->needs_all( map { $_->send( $opcode, $data ) } values %{ $self->{shards} } );
}

sub stats {
    my ($self) = @_;
    return {
        state => $self->state,
        total => $self->{total},
        identify => $self->{limiter}->stats,
        shards => { map { $_ => $self->{shards}{$_}->stats } keys %{ $self->{shards} } }
    };
}

sub close {
    my ($self) = @_;
    return $self->{closing} if $self->{closing};

    # Stop group admission before closing children and the shared scheduler.
    $self->{closed} = 1;
    $self->{state} = 'closed';
    $self->{ready}->fail( $self->_failed( 'Shard manager closed', 'shutdown' )->failure )
        if $self->{ready} && !$self->{ready}->is_ready;
    my @closing = map { $_->close } values %{ $self->{shards} };
    push @closing, $self->{limiter}->close;
    push @closing, $self->{rest}->close if $self->{own_rest};
    $self->{handlers} = {};
    $self->{dispatch_observers} = [];

    # The manager lifetime ends only after all shutdown Futures settle.
    my $future = $self->{closing} = Future->needs_all(@closing);
    $future->on_ready( sub { $self->{completion}->done unless $self->{completion}->is_ready } );
    return $future;
}

1;

__END__

=encoding UTF-8

=head1 NAME

Discord::Client::Gateway::Shards - Gateway shards in one process

=head1 SYNOPSIS

    use Discord::Client;

    # Use Discord's recommended shard count.
    my $bot = Discord::Client->new(
        token => $token, loop => $loop, intents => ['GUILDS'], shards => 'auto',
    );
    $bot->run;

=head1 DESCRIPTION

Runs several Gateways in one process with shared REST discovery and an Identify
scheduler. Startup waits for every shard to be ready. Each shard maintains its
own heartbeat and Resume state. Separate processes need external Identify
coordination.

Callbacks receive the originating child L<Discord::Client::Gateway>.
Each listener has independent failure reporting and uses the child's handler
and queue capacity. A fatal child failure stops the manager; orderly close
stops all children.

=head1 METHODS

=head2 new

C<new(token =E<gt> $token, loop =E<gt> $loop, shards =E<gt> 'auto')> returns a
manager without I/O. C<shards> defaults to C<auto>, using the recommended count
from C</gateway/bot>. A positive integer selects an explicit count.
C<max_shards> defaults to 1024. Other transport and intent options follow
L<Discord::Client::Gateway/new>.

=head2 connect

Discovers Gateway metadata and starts the children. Returns a Future resolving
to the manager when all shards are ready. Cancelling it closes the manager.

=head2 completion

Returns the lifetime Future. It resolves on orderly shutdown and fails when
a child fails fatally.

=head2 close

Closes children and owned resources and returns a Future waiting for cleanup.
Repeated calls return the same Future. An injected REST client remains caller-owned.

=head2 on

C<on(EVENT =E<gt> CODE)> registers a Gateway event callback on every child and
returns the manager. Listeners can be added before or after connecting.

=head2 send

C<send(opcode, data, guild_id =E<gt> ID)> returns a Future for the target guild's
shard write. Use C<shard_id =E<gt> N> to select directly; the default is zero.
Outbound restrictions follow L<Discord::Client::Gateway/send>.

=head2 broadcast

C<broadcast(opcode, data)> requires all shards ready and returns a Future
waiting for all writes. Otherwise it fails with C<state>.

=head2 shard_for_guild

C<shard_for_guild(guild_id)> returns the shard number using
L<Discord's routing rule|https://docs.discord.com/developers/events/gateway#sharding>,
C<(guild_id E<gt>E<gt> 22) % shard_count>, with arbitrary-precision arithmetic.
Invalid IDs or an undiscovered count throw.

=head2 shards

Returns a copied hashref mapping shard IDs to child Gateway objects.

=head2 state

Returns C<ready> when all children are ready, C<reconnecting> during recovery,
or the current startup/shutdown state.

=head2 loop

Returns the IO::Async::Loop.

=head2 identify_limiter

Returns the shared internal Identify scheduler. Its API is not a public contract.

=head2 stats

Returns a hashref with state, total shard count, child counters and Identify budget.

=head1 LICENSE

Apache License 2.0.

=cut
