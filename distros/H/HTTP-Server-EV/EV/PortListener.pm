package HTTP::Server::EV::PortListener;
use strict;
use IO::Socket::INET;
use Carp;
use Scalar::Util qw/weaken/;
our $VERSION = '0.69';

=head1 NAME

HTTP::Server::EV::PortListener - Port listener

=head1 METHODS

=head2 $listener->stop;

Stops listening port. All already running requests will be processed

=head2 $listener->start;

Starts listening port.

=cut


sub new {
	my ($pkgname, $self) = @_;
	$self = bless $self;
	
	unless($self->{socket}){
		croak("Port undefined!") unless  $self->{port};
	
		$self->{socket} = IO::Socket::INET->new( 
								Proto     => 'tcp',
								LocalPort => $self->{port},
								Listen    => SOMAXCONN,
								Reuse     => 1
		);
	}
	$self->{socket}->blocking(0);
	
	
	croak("No callback!") unless $self->{cb};
	
	$self->{fork_hook}->() if $self->{fork_hook};
	
	$self->{ptr} =
		HTTP::Server::EV::listen_socket( # socket, cb, on_multipart_cb, on_error, timeout
				$self->{socket}->fileno ,
				
				$self->{threading} ? 
					sub { Coro->new( $self->_create_main_cb( $self->{cb}) , @_)->ready } 
					: 
					$self->_create_main_cb( $self->{cb} ) ,  
					
				sub { 
					$_[0]->{parent_listener} = $self;
					weaken $_[0]->{parent_listener};
					
					$self->{on_multipart}->(@_) if $self->{on_multipart};
				},
				sub { 
					$self->{on_error}->(@_) if $self->{on_error};
				},
				
				( $self->{timeout} // 60 ) # 60 if undef
		);
	
	
	
	return $self;
}
use Socket;


sub _create_main_cb {
	my ($self,$cb) = @_;
	return sub { 
		my $cgi = $_[0];
		
		unless($cgi->{parent_listener}){
			$cgi->{parent_listener} = $self;
			weaken $cgi->{parent_listener};
		}
		
		$cgi->{buffer}{error_w}->start if(
			($cgi->{headers}{REQUEST_METHOD} eq 'GET') or
			($cgi->{headers}{REQUEST_METHOD} eq 'POST')
		);
		
		eval { $cb->($cgi); };
		if($@){ warn "ERROR IN CALLBACK: $@"; }
		
		return;
		
		NEXT_REQ:
		$cgi->close;
	};
}



sub start {
	$_[0]->{stopped} = 0;
	HTTP::Server::EV::start_listen($_[0]->{ptr});
}


sub stop {
	$_[0]->{stopped} = 1;
	HTTP::Server::EV::stop_listen($_[0]->{ptr});
}



1;