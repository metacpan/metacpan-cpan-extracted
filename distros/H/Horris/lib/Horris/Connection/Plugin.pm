package Horris::Connection::Plugin;
# ABSTRACT: Base Package of Plugins


use Moose;
use namespace::clean -except => qw/meta/;

has connection => (
	is => 'ro', 
	isa => 'Horris::Connection', 
	writer => '_connection'
);

has is_enable => (
	traits => ['Bool'], 
	is => 'rw', 
	isa => 'Bool', 
	default => 1, 
	handles => {
		enable => 'set', 
		disable => 'unset', 
		_switch => 'toggle', 
		is_disable => 'not'
	}
);

has pass => (
	is => 'ro',
	isa => 'Int',
	default => 0,
);

has done => (
	is => 'ro',
	isa => 'Int',
	default => 1,
);

sub init {
	my ($self, $conn) = @_;
	my $pname = ref $self;
	print $pname, " on - ", $self->is_enable ? 'enable' : 'disable', "\n" if $Horris::DEBUG;
	$self->_connection($conn);
}

around BUILDARGS => sub {
	my ($orig, $class, @args) = @_;
	my $self = $class->$orig(@args);
	my @reserve_keys = qw/parent name/;
	while (my ($key, $value) = each %{ $self->{parent}{plugin}{$self->{name}} }) {
		confess 'keys [' . join(', ', @reserve_keys) . "] are reserved\n" if grep { $key eq $_ } @reserve_keys;
		$self->{$key} = $value;
	}

	return $self;
};

__PACKAGE__->meta->make_immutable;

1;

__END__
=pod

=encoding utf-8

=head1 NAME

Horris::Connection::Plugin - Base Package of Plugins

=head1 VERSION

version v0.1.2

=head1 SYNOPSIS

    package Horris::Connection::Plugin::Foo;
    use Moose;
    with qw/Horris::Connection::Plugin MooseX::Role::Pluggable::Plugin/;

    # override member variables if you want.
    has '+is_enable' => (
        default => 0	# $self->is_enable is false
    );

    sub init {
        # initialize plugin stuff here
    }

    sub on_connect {
        # implement on_connect stuff here
    }

    sub on_disconnect {
        # implement on_disconnect stuff here
    }

    sub irc_privmsg {
        my ($self, $message) = @_;
        #	this hook method will called by Horris::Connection
        #	when 'irc_privmsg' event occur in joinning irc channels
        #	see the AnyEvent::IRC::Client for 'irc_privmsg' more detail
        #
        # implement irc_privmsg stuff here
    }

    sub on_privatemsg {
        my ($self, $nick, $message) = @_;
        # this hook method will called when who send a private message to
        # your bot. 
    }

    __PACKAGE__->meta->make_immutable;

    # see the documentation for MooseX::Role::Pluggable,
    # MooseX::Role::Pluggable::Plugin for info on how to get your Moose
    # class to use this plugin...

=head1 SEE ALSO

L<MooseX::Role::Pluggable> L<MooseX::Role::Pluggable::Plugin> L<Horris::Connection>

=head1 AUTHOR

hshong <hshong@perl.kr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by hshong.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

