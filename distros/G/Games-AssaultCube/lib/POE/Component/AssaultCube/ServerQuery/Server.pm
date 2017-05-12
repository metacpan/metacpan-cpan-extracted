# Declare our package
package POE::Component::AssaultCube::ServerQuery::Server;

# import the Moose stuff
use Moose;
use MooseX::StrictConstructor;

# Initialize our version
use vars qw( $VERSION );
$VERSION = '0.04';

use Games::AssaultCube::Utils qw( default_port );
use Time::HiRes qw( time );

# TODO improve validation for everything here, ha!

has 'ID' => (
	isa		=> 'Str',
	is		=> 'ro',
	lazy		=> 1,
	default		=> sub {
		my $self = shift;
		return $self->server . ':' . $self->port;
	},
);

has 'server' => (
	isa		=> 'Str',
	is		=> 'ro',
	required	=> 1,
);

has 'port' => (
	isa		=> 'Int',
	is		=> 'ro',
	lazy		=> 1,
	default		=> sub {
		return default_port;
	},
);

has 'last_pingtime' => (
	isa		=> 'Num',
	is		=> 'rw',
	default		=> 0,
);

has 'frequency' => (
	isa		=> 'Num',
	is		=> 'rw',
	default		=> 300,
);

has 'get_players' => (
	isa		=> 'Bool',
	is		=> 'rw',
	default		=> 0,
);

sub nextping {
	my $self = shift;

	# if it was never pinged, do it now!
	if ( $self->last_pingtime == 0 ) {
		return 0;
	}

	my $pingtime = ( $self->last_pingtime + $self->frequency ) - time();

#warn "server(" . $self->ID . ") last_pingtime(" . $self->last_pingtime . ") frequency(" . $self->frequency . ") time(" . time() . ") pingtime(" . $pingtime . ")";

	if ( $pingtime < 0 ) {
		return 0;
	} else {
		return $pingtime;
	}
}

sub BUILDARGS {
	my $class = shift;

	if ( @_ == 1 && ! ref $_[0] ) {
		# set the server as the first argument
		return { server => $_[0] };
	} elsif ( @_ == 2 && ! ref $_[0] ) {
		# server/port argument
		return { server => $_[0], port => $_[1] };
	} else {
		# normal hash/hashref way
		return $class->SUPER::BUILDARGS(@_);
	}
}

# from Moose::Manual::BestPractices
no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=for stopwords nextping playerlist PoCo hostname ip

=head1 NAME

POE::Component::AssaultCube::ServerQuery::Server - Holds the server info

=head1 SYNOPSIS

	use POE::Component::AssaultCube::ServerQuery;

	sub _start {
		my $query = POE::Component::AssaultCube::ServerQuery->new;
		$query->register;
		my $server = POE::Component::AssaultCube::ServerQuery::Server->new( {
			server		=> '123.123.123.123',
			frequency	=> 60,
		} );
		$query->addserver( $server );
	}

=head1 ABSTRACT

Holds the server info

=head1 DESCRIPTION

This module represents a server for the PoCo to ping. There are a few values to twiddle.

=head2 Constructor

This module uses Moose, so you can pass either a hash or a hashref to the constructor.

The attributes are:

=head3 server

The server ip.

NOTE: Input in the form of a hostname is not currently supported. Please resolve it before
instantiation of this object! A good module to use would be L<POE::Component::Client::DNS> or
anything else.

=head3 port

The server port. Defaults to 28763.

WARNING: AssaultCube uses $port+1 for the query port. Please do not do pass $port+1 to the constructor,
we do it internally. Maybe in the future AC will use $port+2 or another system, so let us deal with it :)

=head3 frequency

A number in seconds ( can be floating-point )

How long we should wait before sending the next ping.

Default: 300

=head3 get_players

Should we also retrieve the playerlist? This is a boolean which defaults to false.

=head2 Methods

There are some methods you can call on the object:

=head3 ID

Returns the PoCo-assigned ID for this server.

=head3 nextping

Returns how many seconds to the next ping, or 0 if it should be done now.

=head2 Attributes

You can modify some attributes while the server is being pinged:

=head3 frequency

Same as the constructor

=head3 get_players

Same as the constructor

=head1 AUTHOR

Apocalypse E<lt>apocal@cpan.orgE<gt>

Props goes to Getty and the BS clan for the support!

This project is sponsored by L<http://cubestats.net>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 by Apocalypse

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
