package HTTP::Server::EV::IO::AIO;
use strict;
use Fcntl qw(:DEFAULT :flock);
use IO::AIO;
use AnyEvent::AIO;
use Scalar::Util qw/weaken/;
use File::Util qw/escape_filename/;
no warnings;

sub _use_me { # i'm not using ISA for performance
	*HTTP::Server::EV::MultipartFile::save = *save;
	*HTTP::Server::EV::MultipartFile::fh = *fh;
	*HTTP::Server::EV::MultipartFile::close = *close;
	*HTTP::Server::EV::MultipartFile::DESTROY = *DESTROY;
	
	*HTTP::Server::EV::MultipartFile::_new = *_new;
	*HTTP::Server::EV::MultipartFile::_flush = *_flush;
	*HTTP::Server::EV::MultipartFile::_done = *_done;
	
}


our $VERSION = '0.69';

=head1 NAME

HTTP::Server::EV::IO::AIO - Implements L<HTTP::Server::EV::MultipartFile> using L<IO::AIO>

=cut

sub save {
	my ($self, $dest, $cb) = @_;
	$self->close(sub {
	
		if( $self->{moved} ){
			aio_copy $self->{path}, $dest, sub{
				warn __PACKAGE__." failed to copy file $self->{path} to $dest - $! \n" 
					unless ($_ = ($_[0] >= 0));
				$cb->($_) if $cb;
			}
		} else {
			aio_move $self->{path}, $dest, sub {
				if($_ = ($_[0] >= 0)) {
					$self->{path} = $dest;
					$self->{moved} = 1;
				} else {
					warn __PACKAGE__." failed to move file $self->{path} to $dest - $! \n"
				}
				$cb->($_) if $cb;
			};
		};
		
	});
	
	if(!$cb and $Coro::current and $_[0]->{parent_req}{parent_listener}{threading}) {
		$cb = Coro::rouse_cb();
		return Coro::rouse_wait();
	}
	1;
};


sub DESTROY {
	my ($self) = @_;
	
	return unless $self->{path}; # one of my programs called destructor two times and i'm too lazy to find why
	
	$self->close(sub {
		aio_unlink ( $self->{path}, sub {
			warn __PACKAGE__." failed to delete file $self->{path} - $! \n" if ($_[0] < 0);
			delete $self->{path};
		}) unless $self->{moved};
	});
}


sub fh {
	my ($self, $cb) = @_;
	
	
	if($self->{fh}){
		if($cb){
			$cb->($self->{fh});
		}
		elsif(!$_[0]->{parent_req}{parent_listener}{threading}){
			die "HTTP::Server::EV::IO::AIO->fh used without a callback. Use Coro and enable threading for listener if you want blocking interface\n"
		}
		
		return $self->{fh};
	};
	
	
	aio_open $self->{path}, 
		IO::AIO::O_RDWR | 
		IO::AIO::O_CREAT , 
		0755, sub {
			if($_[0] < 0){
				warn __PACKAGE__." failed to open file $self->{path} - $! \n";
				$cb->(undef);
			} else {
				binmode(($self->{fh} = $_[0]));
				$cb->($self->{fh});
			}
		};
	unless( $cb ){
		if($Coro::current and $_[0]->{parent_req}{parent_listener}{threading}) {
			$cb = Coro::rouse_cb();
			return Coro::rouse_wait();
		}
		else {
			die "HTTP::Server::EV::IO::AIO->fh used without a callback. Use Coro and enable threading for listener if you want blocking interface\n"
		}
	}
};



sub close {
	my ($self, $cb) = @_;
	
	$cb->(1) unless $self->{fh};
	
	aio_close $self->{fh}, sub {
		if ($_ = ($_[0] >= 0) ) {
			close delete $self->{fh};
		} else {
			warn __PACKAGE__." failed to close file $self->{path} - $! \n";
		};
		$cb->($_);
	};
	1;
}


my @chars = ('A'..'Z', 'a'..'z', 0..9);

sub _new {
	my ($self) = @_;
	
	$self->{path} = $HTTP::Server::EV::tmp_path.'/';
	$self->{path} .= @chars[rand @chars] for 1..50;
	
	$self->{name} = escape_filename($self->{name});
	$self->{name} =~s/\x{0}//g;
	
	$self->fh(sub {
		if ($self->{fh}) {
		
			$self->{parent_req}{parent_listener}{on_file_open}->( $self->{parent_req}, $self) 
				if $self->{parent_req}{parent_listener}{on_file_open};
			
			$self->{parent_req}->start;
		} else {
			$self->{parent_req}->drop;
		}
	});
	
	$self->{parent_req}->stop;
}

sub _flush {
	my ($self, $data) = @_;
	
	aio_write($self->{fh}, $self->{size}, length($data) , $data, 0, sub {
		if ($_[0] > 0) {
			$self->{size} += $_[0];
			
			$self->{parent_req}{parent_listener}{on_file_write}->( $self->{parent_req}, $self, $data) 
				if $self->{parent_req}{parent_listener}{on_file_write};
			
			$self->{parent_req}->start;
		} else {
			warn __PACKAGE__." failed to write file $self->{path} - $! \n";
			$self->{parent_req}->drop;
		};
	});
	
	$self->{parent_req}->stop;
}


sub _done{
	$_[0]->{parent_req}{parent_listener}{on_file_received}->($_[0]->{parent_req}, $_[0]) if $_[0]->{parent_req}{parent_listener}{on_file_received};
}

1;