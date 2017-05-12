package Message::Passing::Redis::Role::HasAConnection;
use Moo::Role;
use Message::Passing::Redis::ConnectionManager;
use namespace::clean -except => 'meta';

with qw/
    Message::Passing::Role::HasAConnection
    Message::Passing::Role::HasHostnameAndPort
/;

sub _default_port { 6379 }

sub _build_connection_manager {
    my $self = shift;
    Message::Passing::Redis::ConnectionManager->new(map { $_ => $self->$_() }
        qw/ hostname port /
    );
}

1;

