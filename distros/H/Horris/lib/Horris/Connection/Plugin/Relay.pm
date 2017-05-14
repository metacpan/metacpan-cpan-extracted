package Horris::Connection::Plugin::Relay;
# ABSTRACT: Relay Plugin on Horris


use Moose;
use AnyEvent::MP qw(configure port rcv snd);
use AnyEvent::MP::Global qw(grp_reg grp_mon grp_get);
use namespace::clean -except => qw(meta);
use Encode ();
 
extends 'Horris::Connection::Plugin';
with 'MooseX::Role::Pluggable::Plugin';

has group => (
    is => 'ro',
    isa => 'Str',
    default => 'morris',
    required => 1,
);

has profile => (
    is => 'ro',
    isa => 'Str',
    default => 'morris',
    required => 1,
);
 
has from => (
    traits => [ 'Hash' ],
    is => 'ro',
    isa => 'HashRef',
    required => 1,
    handles => {
      get_instance => 'get',
    }
);
 
has __guard => (
    is => 'rw',
    clearer => 'clear_guard',
);
 
around BUILDARGS => sub {
    my ($next, $class, @args) = @_;
    my $args = $next->($class, @args);
    return $args;
};

sub on_connect {
	my ($self) = @_;

	my $conn = $self->connection;
    my $server = port;
    rcv $server, notice => sub {
        my ($channel, $message) = @_;
        $conn->irc_notice( {
            channel => $channel,
            message => $message
        });
    };
    rcv $server, privmsg => sub {
        my ($channel, $message) = @_;
        $conn->irc_privmsg( {
            channel => $channel,
            message => $message
        });
    };
	warn "MP Server - $server\n";
    $self->__guard( grp_reg $self->group, $server );

	return $self->pass;
}

sub irc_privmsg {
    my ($self, $msg) = @_;
 
    my $channel = $msg->channel;
    my $message = $msg->message;
    my $nickname = $msg->nickname;

    return unless $channel;
    return unless $message;

    my $config = $self->from->{'\\'.$channel};

	return unless $config;

	my $ports = grp_get $config->{target};
	if($ports) {
		my $server = $ports->[0];
		my $msg = sprintf('<%s> %s', $nickname, $message);
		if ($config->{encode} && $config->{decode}) {
		$msg = Encode::encode($config->{encode}, Encode::decode($config->{decode}, $msg));
		}

		snd $server, $config->{type} => $_, $msg for @{ $config->{to} };
	}
}
 
__PACKAGE__->meta->make_immutable();
 
1;
 


=pod

=encoding utf-8

=head1 NAME

Horris::Connection::Plugin::Relay - Relay Plugin on Horris

=head1 VERSION

version v0.1.2

=head1 SYNOPSIS

    <Plugin MP::Relay>
        <From \#perl-kr>
            Target freenode
            To \#perl
            Type privmsg
        </From>
    </Plugin>

=head1 DESCRIPTION

Relay

=head1 SEE ALSO

L<AnyEvent::MP>

=head1 AUTHOR

hshong <hshong@perl.kr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by hshong.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__
 
config
 
...
<Plugin MP::Relay>
<From \#perl-kr>
Target freenode
To \#perl
Type privmsg
</From>
</Plugin>
...
