package Device::Gembird;

use 5.006;
use strict;
use warnings FATAL => 'all';

use Carp;
use IO::Socket;
use IO::Select;

our @ISA = qw(Exporter);

use constant SOCK_ON    => 0x01;
use constant SOCK_OFF   => 0x02;
use constant SOCK_SKIP  => 0x04;
use constant SOCK_ERROR => 0x08;

use constant SOCK_STATE_DISCONNECTED    => 0x00;
use constant SOCK_STATE_CONNECTED       => 0x01;
use constant SOCK_STATE_AUTHENTICATED   => 0x02;

use constant SOCK_ERROR_OK              => 0x00;
use constant SOCK_ERROR_HOST            => 0x01;
use constant SOCK_ERROR_REFUSED         => 0x02;
use constant SOCK_ERROR_SECRET          => 0x04;
use constant SOCK_ERROR_WRITE           => 0x08;
use constant SOCK_ERROR_READ            => 0x10;

our @EXPORT = qw( SOCK_ON SOCK_OFF SOCK_SKIP );

=head1 NAME

Device::Gembird - control Gembird EG-PMS-LAN or similar device.

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

    use Device::Gembird;

    my $foo = Device::Gembird->new( host => '192.168.1.67', secret => '1' );
    $foo->socket1(SOCK_OFF);
    $foo->socket2(SOCK_ON);
    my $state = $foo->socket3();
    my $new_state = $foo->socket4(SOCK_ON);
    ...

=head1 DESCRIPTION

This module allows to control voltage
on Gembird EnerGenie EG-PMS-LAN Programmable surge protector
via LAN interface.

=head1 METHODS

=head2 new

Method creates new object with parameters:
 - host => host to connect to
 - port => port to connect to. default is 5000.
 - timeout => timeout for TCP operation. default is 3 sec.
 - secret => secret of device. default is '1'.

=cut

sub new {
	my $invocant = shift;
	my $class    = ref($invocant) || $invocant;
	my $self     = {
		port              => 5000,
		secret            => '1',
		last_error        => '',
		timeout           => 3,
		'state'           => 0,
		@_
	};
	bless( $self, $class );
	return $self;
}

=head2 get_last_error

Returns last error occurred while communicating

=cut

sub get_last_error {
	my $self = shift;
	return $self->{last_error};
}

=head2 socket1

Sets new state of Socket 1 (if was specified)
returns current state of Socket 1

=cut

sub socket1 {
	my $self = shift;
	my $control = shift;
	if ($control) {
		$self->_set_ctrl( $control, SOCK_SKIP, SOCK_SKIP, SOCK_SKIP );
	}
	return $self->_resolve_state(0);
}

=head2 socket2

Sets new state of Socket 2 (if was specified)
returns current state of Socket 2

=cut

sub socket2 {
	my $self = shift;
	my $control = shift;
	if ($control) {
		$self->_set_ctrl( SOCK_SKIP, $control, SOCK_SKIP, SOCK_SKIP );
	}
	return $self->_resolve_state(1);
}

=head2 socket3

Sets new state of Socket 3 (if was specified)
returns current state of Socket 3

=cut

sub socket3 {
	my $self = shift;
	my $control = shift;
	if ($control) {
		$self->_set_ctrl( SOCK_SKIP, SOCK_SKIP, $control, SOCK_SKIP );
	}
	return $self->_resolve_state(2);
}

=head2 socket4

Sets new state of Socket 4 (if was specified)
returns current state of Socket 4

=cut

sub socket4 {
	my $self = shift;
	my $control = shift;
	if ($control) {
		$self->_set_ctrl( SOCK_SKIP, SOCK_SKIP, SOCK_SKIP, $control );
	}
	return $self->_resolve_state(3);
}

sub _resolve_state {
	my $self = shift;
	my $socket = shift;
	my $res = SOCK_ERROR;
	if ($self->{stat} and exists($self->{stat}->[$socket])) {
		my $state = $self->{stat}->[$socket];
		if ($state == 17) {
			$res = SOCK_ON;
		}
		elsif ($state == 34) {
			$res = SOCK_OFF;
		}
	}
	return $res;
}

sub _append_args {
	my $self = shift;
	my %args = @_;
	while ( my( $k, $v ) = each %args ) {
		$self->{$k} = $v;
	}
}

sub _ord {
	my $self = shift;
	my( $str, $offset ) = @_;
	return ord(substr( $str, $offset, 1 ));
}

sub _get_state {
	my $self = shift;
	if ($self->{poller}->can_read(1.0)) {
		$self->{sock}->recv( my $state, 4 );

		for ( my $i = 0; $i < 4; $i++ ) {
			$self->{stat}->[3-$i]=(
				(
					(
						(
							(
								$self->_ord( $state, $i ) -
								  $self->_ord( $self->{secret}, 1 )
							)
						) ^ $self->_ord( $self->{secret}, 0 )
					) - $self->_ord( $self->{task}, 3 )
				) ^ $self->_ord( $self->{task}, 2 )
			) & 0xFF;
		}
	}
	else {
		return $self->_set_last_error(SOCK_ERROR_READ);
	}
}

sub _set_ctrl {
	my $self = shift;
	my @ctrl = @_;
	my $ctrl = '';
	my $attempt = 0;
	my $res = 0;
	do {
		if (( $self->{'state'} & SOCK_STATE_CONNECTED ) !=SOCK_STATE_CONNECTED )
		{
			$res = $self->_connect();
		}
		if ( !$res
			and ( $self->{'state'} & SOCK_STATE_AUTHENTICATED ) !=
			SOCK_STATE_AUTHENTICATED )
		{
			$res = $self->_auth();
		}
	} while ($res and $attempt++ < 3);
	if ($res) {
		return $res;
	}
	for ( my $i = 0; $i < 4; $i++ ) {
		$ctrl[3-$i] ||= SOCK_SKIP;
		if ($ctrl[3-$i] > SOCK_SKIP) {
			$ctrl[3-$i] = SOCK_SKIP;
		}
		$ctrl .= chr(
			(
				(
					(
						( $ctrl[3-$i] ^ $self->_ord( $self->{task}, 2 ) ) +
						  $self->_ord( $self->{task}, 3 )
					) ^ $self->_ord( $self->{secret}, 0 )
				) + $self->_ord( $self->{secret}, 1 )
			) & 0xFF
		);
	}
	$attempt = 0;
	$res = 0;
	do {
		if ($self->{poller}->can_write(1.0)) {
			$self->{sock}->send($ctrl);
		}
		else {
			$res = $self->_set_last_error(SOCK_ERROR_WRITE);
		}
	} while ( $res and $attempt++ < 3 );
	if ($res) {
		return $res;
	}
	$self->_get_state();
}

sub _auth {
	my $self = shift;
	$self->_append_args(@_);
	unless (exists($self->{secret})) {
		return $self->_set_last_error(SOCK_ERROR_SECRET);
	}
	my $len = length($self->{secret});
	if ( $len > 8 ) {
		$self->{secret} = substr($self->{secret}, 0, 7);
	}
	elsif ( $len < 8 ) {
		$self->{secret} .= ' ' x ( 8 - $len );
	}
	if ( ( $self->{'state'} & SOCK_STATE_CONNECTED ) == SOCK_STATE_CONNECTED ) {
		if ($self->{poller}->can_write(1.0)) {
			$self->{sock}->send(chr(0x11));
		}
		else {
			return $self->_set_last_error(SOCK_ERROR_WRITE);
		}
		if ($self->{poller}->can_read(1.0)) {
			$self->{sock}->recv( $self->{task}, 4 );
		}
		else {
			return $self->_set_last_error(SOCK_ERROR_READ);
		}
		if (length($self->{task}) == 4) {
			my $res10 =
			  (($self->_ord($self->{task},0)^$self->_ord($self->{secret},2))*
				  $self->_ord($self->{secret},0))
			  ^($self->_ord($self->{secret},6)|
				  ($self->_ord($self->{secret},4)<<8))
			  ^$self->_ord($self->{task},2);
			my $res32 =
			  (($self->_ord($self->{task},1)^$self->_ord($self->{secret},3))*
				  $self->_ord($self->{secret},1))
			  ^($self->_ord($self->{secret},7)|
				  ($self->_ord($self->{secret},5)<<8))
			  ^$self->_ord($self->{task},3);
			my $res =
			    chr($res10 & 0xFF)
			  . chr($res10 >> 8)
			  . chr($res32 & 0xFF)
			  . chr($res32 >> 8);

			if ($self->{poller}->can_write(1.0)) {
				$self->{sock}->send($res);
			}
			else {
				return $self->_set_last_error(SOCK_ERROR_WRITE);
			}
			$self->{'state'} |= SOCK_STATE_AUTHENTICATED;
			$self->_get_state();
		}
	}
	return SOCK_ERROR_OK;
}

sub _connect {
	my $self = shift;
	$self->_append_args(@_);
	unless (exists($self->{host}) and exists($self->{port})) {
		return $self->_set_last_error(SOCK_ERROR_HOST);
	}

	$self->{sock} = new IO::Socket::INET(
		PeerHost      => $self->{host},
		PeerPort      => $self->{port},
		Timeout       => $self->{timeout},
		Proto         => 'tcp',
	);

	if ($self->{sock} && $self->{sock}->connected) {
		$self->{'state'} |= SOCK_STATE_CONNECTED;
		$self->{poller} = IO::Select->new();
		$self->{poller}->add($self->{sock});
	}
	else {
		return $self->_set_last_error(SOCK_ERROR_REFUSED);
	}
	return SOCK_ERROR_OK;
}

sub _set_last_error {
	my $self = shift;
	my $code = shift;
	if ($code == SOCK_ERROR_OK) {
		$self->{last_error} = '';
	}
	elsif ($code == SOCK_ERROR_HOST) {
		$self->{'state'} = SOCK_STATE_DISCONNECTED;
		$self->{last_error} = "Host or port not specified";
	}
	elsif ($code == SOCK_ERROR_REFUSED) {
		$self->{'state'} = SOCK_STATE_DISCONNECTED;
		$self->{last_error} = "Failed to connect";
	}
	elsif ($code == SOCK_ERROR_SECRET) {
		$self->{last_error} = "Secret not specified";
	}
	elsif ($code == SOCK_ERROR_WRITE) {
		$self->{last_error} = "Socket is not ready for writing";
	}
	elsif ($code == SOCK_ERROR_READ) {
		$self->{last_error} = "Socket is not ready for reading";
	}
	return $code;
}

=head1 AUTHOR
Leandr Khaliullov, C<< <leandr at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-device-gembird at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Device-Gembird>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Device::Gembird


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Device-Gembird>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Device-Gembird>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Device-Gembird>

=item * Search CPAN

L<http://search.cpan.org/dist/Device-Gembird/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2014 Leandr Khaliullov.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Device::Gembird
