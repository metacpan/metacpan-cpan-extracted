package HTTP::Server::EV::Buffer;
our $VERSION = '0.69';

use strict;
use bytes;
use EV;
use Scalar::Util qw/weaken/;
use Carp;
use IO::Handle;

=head1 NAME

HTTP::Server::EV::Buffer - Non-blocking output buffer.  

=head1 GLOBAL PARAMETERS

$HTTP::Server::EV::Buffer::autoflush = 1024*10; # Default buffered data size in bytes when buffer starts waiting socket to be writable to send data. Setting 0 disables buffering, data will be sent as soon as socket becomes writable.

=cut


our $autoflush = 1024*50; 


=head1 METHODS

=head2 new({ fh => $sock_handle , flush => autoflush_threshold(optional), 
onerror => sub { onerror(disconect) optional callback} });

Creates new HTTP::Server::EV::Buffer object. 

=cut

# when buffer is destroed at main program it will be placed here to send all data, close socket and destroy itself completely
our %buffers; 

#$self->{status} = 
# -1 - error, socket closed
# 0 - flush buffer until buffred data greater than autoflush threshold (default)
# 1 - flush entire buffer and set status to 0 (->flush call)
# 2 - flush entire buffer, delete watcher and close socket(on DESTROY)



sub new {
	my ($name, $self) = @_;
	
	$self->{flush} = $autoflush unless exists $self->{flush};

	
	$self->{fh} ||= IO::Handle->new_from_fd($self->{fd}, 'r+' )
		or croak 'Cant create filehandle from fd!';
	$self->{fh}->blocking ( 0 );
	
	# break circular because onneror possible contains closure with H:S:E::CGI object that contains ref to buffer
	# weaken $self->{onerror} if $self->{onerror};
	
	weaken $self; # break circular ref. 
	
	####### oneror (ondisconnect) callback #######
	$self->{error_w} = EV::io_ns $self->{fd}, EV::READ, sub { # socket becomes readable when clinet closes connection
	
		delete $self->{buffer}; # buffer deleted. 
		$self->{status} = -1; # when status -1 ->print will not place new data in buffer so DESTROY will not place this buffer to %buffers
		$self->{onerror}->() if $self->{onerror};
		
		$_[0]->stop;
	};
	
	####### write cb ########
	$self->{w} = EV::io_ns $self->{fh}, EV::WRITE, sub {
		
		my $bytes = send(
			$self->{fh}, 
			( $self->{flush} ? 
				substr($self->{buffer}, 0, $self->{flush}) : 
				$self->{buffer}
			),
			0
		);
		
		$self->{error_w}->invoke unless( defined $bytes ); # send error. invoke onerror cb
		
		substr($self->{buffer}, 0, $bytes) = ''; # delete sent data
		
		if( length($self->{buffer}) <= $self->{flush} ){
			if($self->{status}){
				if( length $self->{buffer} ){
					return;
				}else{
					if($self->{flush_cb}){
						$self->{flush_cb}->();
						$self->{flush_cb} = undef;
					}
					
					if( $self->{status} == 1 ){ # status 1 - just flush data
						$self->{status} = 0;
					}else{ # staus = 2 (all flushed and close) or -1 (client closed socket)
						delete $buffers{$self->{fd}};
						$_[0]->stop;
						return; # now it calls DESTROY (or not calls if status -1 and other code holds reference) again and closes the socket
					}
					
				}
			}
			$_[0]->stop;
		}
		
	};
	
	bless $self, $name;
}



sub TIEHANDLE { # pkgname, buffer obj
	return $_[1];
}

*TIESCALAR=\&TIEHANDLE;


=head2 $buffer->print(@args)

Prints data to buffer.

=cut



sub WRITE {
	return if $_[0]->{status} < 0;
	$_[0]->{buffer} .=  substr $_[1], 0, $_[2];
	$_[0]->{w}->start if(length($_[0]->{buffer}) > $_[0]->{flush});
}


sub print {
	return if $_[0]->{status} < 0;

	my $self = shift;
	
	$self->{buffer} .= join( ($, // ''), @_) . ($\ // '');
	
	$self->{w}->start if(length($self->{buffer}) > $self->{flush});
}

*PRINT=\&print;

sub PRINTF {
	return if $_[0]->{status} < 0;

	my $self = shift;
	
	$self->{buffer} .= sprintf(shift, @_);
	
	$self->{w}->start if(length($self->{buffer}) > $self->{flush});
}


sub onerror {$_[0]->{onerror} = $_[1] }


=head2 $buffer->flush( $flush_threshold(optional) )

Sends all buffered data to socket and sets new flush threshold if $flush_threshold defined;

=head2 $buffer->flush_wait( sub{} )

->flush only starts sending data in async background mode. ->flush_wait starts flushing and calls callback when all data is sent. If callback isn't specified it will try use Coro to block current thread (threading in PortListener must be enabled). If threading disabled and no callback specified it works as ->flush

=head2 $buffer->{onerror} = sub {} or  $buffer->onerror(sub {})

Set onerror callback, which called when client disconeted before cerver closed connection. 

=head2 $buffer->give_up_handle

Use when you need do some bi-directional communication through client socket(for ex. websocket server or make CONNECT proxy). Returns filehandle opened for RW and now buffer won't do anything with handle - $buffer will be set to undef; Call ->flush_wait before calling ->give_up_handle if you have data in buffer, otherwise it will be lost

=head2 $buffer->{error_w}->start

Call this after ->new if you use H:S:E:Buffer without HTTP::Server::EV and need onerror callback. It's called automatically after receiving GET or POST request, for other methods you must start watcher manually after reading all data from handle.

=cut

## Buffer (inside CGI object) object initialized when server starts receiving POST data. Error callback triggers when socket becomes readable and must be started when all data received, otherwise it will trigger after initializing buffer obj because sock is readable (there is post body in it).


sub flush {
	$_[0]->{flush} = $_[1] if defined $_[1];
	
	if(length $_[0]->{buffer}){
		$_[0]->{status} = 1;
		$_[0]->{w}->start;
	}
}
sub flush_wait {
	if(length $_[0]->{buffer}){
		$_[0]->{status} = 1;
		$_[0]->{w}->start;
		
		if($_[1]){
			$_[0]->{flush_cb} = $_[1];
		} else{
			$_[0]->{flush_cb} = Coro::rouse_cb();
			return Coro::rouse_wait();
		}
	}
}

sub give_up_handle {
	$_[0]->{_deleted} = 1; # disable destructor
	
	my $fh = $_[0]->{fh};
	
	$_[0] = undef;
	
	$fh;
}


sub DESTROY {
	return if $_[0]->{_deleted};
	if(length $_[0]->{buffer}){
		$_[0]->{status} = 2;
		$_[0]->{w}->start;
		$buffers{$_[0]->{fd}} = $_[0];
	}else{
		close $_[0]->{fh};
	}
}


# read-only

sub READLINE { croak "HTTP::Server::EV::Buffer doesn't support a READLINE method"; }
sub GETC { croak "HTTP::Server::EV::Buffer doesn't support a GETC method"; }
sub READ { croak "HTTP::Server::EV::Buffer doesn't support a READ method"; }



1;