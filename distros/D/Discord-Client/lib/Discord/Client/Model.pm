package Discord::Client::Model;

use v5.26;
use strict;
use warnings;
use Carp qw(croak);
use JSON::PP ();
use Future;
use Discord::Client::Error;

our $VERSION = '0.001';

sub new {
    my ( $class, %args ) = @_;

    # Require a resource identity before constructing a detached JSON snapshot.
    croak 'Model data requires an ID'
        unless ref( $args{data} ) eq 'HASH'
        && defined( $args{data}{id} )
        && !ref( $args{data}{id} )
        && $args{data}{id} =~ /\A\d{1,20}\z/;
    my $data = eval { _clone( $args{data} ) };
    croak 'Model data must be JSON encodable' if $@;
    $data->{id} = "$data->{id}";
    return bless { data => $data, rest => $args{rest} }, $class;
}

sub _clone {
    my ($data) = @_;

    # Support scalar field values as well as nested resource data.
    my $json = JSON::PP->new->allow_nonref;
    return $json->decode( $json->encode($data) );
}
sub id { $_[0]->{data}{id} }
sub raw { _clone( $_[0]->{data} ) }
sub get { _clone( $_[0]->{data}{ $_[1] } ) }
sub rest { $_[0]->{rest} }

sub wrap {
    my ( $class, $type, $data, %args ) = @_;

    # Load only known model classes; caller input never becomes an arbitrary module path.
    my %classes = ( message => 'Message', channel => 'Channel', guild => 'Guild', user => 'User' );
    croak 'Unknown model type' unless defined($type) && !ref($type) && $classes{$type};
    my $package = 'Discord::Client::Model::' . $classes{$type};
    ( my $file = "$package.pm" ) =~ s{::}{/}g;
    require $file;
    return $package->new( data => $data, %args );
}

sub _call {
    my ( $self, $method, @args ) = @_;

    # Read-only snapshots fail asynchronous operations without constructing a hidden client.
    return $self->_failed( 'Model operation requires a REST client', 'state' ) unless $self->{rest};
    return $self->{rest}->$method(@args);
}

sub _model_future {
    my ( $self, $type, $future ) = @_;

    # Wrap successful responses without mutating the original resource snapshot.
    return $future->then(
        sub {
            my ($data) = @_;
            my $model = eval { __PACKAGE__->wrap( $type, $data, rest => $self->{rest} ) };
            return $self->_failed( 'Discord returned invalid model data', 'protocol' ) unless $model;
            return Future->done($model);
        }
    );
}

sub _failed {
    my ( $self, $message, $category ) = @_;
    my $error = Discord::Client::Error->new( message => $message, category => $category );
    return Future->fail( $message, $category, $error );
}

1;

__END__

=encoding UTF-8

=head1 NAME

Discord::Client::Model - Resource snapshots with optional REST operations

=head1 SYNOPSIS

    use Discord::Client::Model;

    # Wrap existing data without a request.
    my $channel = Discord::Client::Model->wrap(
        channel => {id => $channel_id}, rest => $rest,
    );

    # The Future yields a new Message snapshot.
    my $sent = $channel->send({content => 'Hello', allowed_mentions => {parse => []}});

=head1 DESCRIPTION

Copied resource data with optional REST operations. Snapshots retain unknown
fields and string IDs. They do not refresh or populate a cache automatically.
Wrapping is synchronous and performs no request.

REST operations return Futures and propagate cancellation. Successful operations
return new snapshots; existing objects do not change. Without a REST client,
operations fail with C<state>. The caller owns the REST client.

=head1 METHODS

=head2 wrap

C<Discord::Client::Model-E<gt>wrap(type, hashref, rest =E<gt> $rest)> returns a
L<Discord::Client::Model::Message>, L<Discord::Client::Model::Channel>,
L<Discord::Client::Model::User> or L<Discord::Client::Model::Guild>.
Types are C<message>, C<channel>, C<user> and C<guild>.
Unknown types or invalid data throw. C<rest> is optional for read-only access.

=head2 new

C<new(data =E<gt> $hashref, rest =E<gt> $rest)> constructs a snapshot of the
called class. Data must be JSON-encodable with a decimal-string ID.
Invalid data throws. Normally use C<wrap> or a subclass constructor.

=head2 id

Returns the resource ID as a string.

=head2 raw

Returns a copied data hashref.

=head2 get

C<get(field)> returns a copied field value, or undef when absent.

=head2 rest

Returns the supplied REST client, or undef.

=head1 LICENSE

Apache License 2.0.

=cut
