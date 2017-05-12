package HTTP::Server::EV::IO::Blocking;
use strict;
use File::Copy;
use File::Util qw/escape_filename/;


sub _use_me { # i'm not using ISA for performance
	*HTTP::Server::EV::MultipartFile::save = *save;
	*HTTP::Server::EV::MultipartFile::fh = *fh;
	*HTTP::Server::EV::MultipartFile::DESTROY = *DESTROY;
	
	*HTTP::Server::EV::MultipartFile::_new = *_new;
	*HTTP::Server::EV::MultipartFile::_flush = *_flush;
	
	*HTTP::Server::EV::MultipartFile::_done = *_done;
}


our $VERSION = '0.69';

=head1 NAME

HTTP::Server::EV::IO::Blocking - Implements L<HTTP::Server::EV::MultipartFile> using perlio functions.

=cut

sub save {
	my ($self, $dest, $cb) = @_;
	close delete $self->{fh} if $self->{fh};
	
	my $status = 1;
	if($self->{moved}){
		copy($self->{path}, $dest ) or (warn __PACKAGE__." failed to copy file to $dest - $! \n" and $status = 0);
	}else{
		move($self->{path}, $dest ) or (warn __PACKAGE__." failed to move file to $dest - $! \n" and $status = 0);
		$self->{path} = $dest;
		$self->{moved} = 1;
	}
	
	$cb->($status) if $cb;
	
	return $status;
}

sub fh {
	my ($self, $cb) = @_;
	
	unless($self->{fh}){
		unless( open ($self->{fh}, '<', $self->{path}) ){
			warn __PACKAGE__." failed to open file - $! \n";
			$cb->(undef) if $cb;
			return undef;
		}
		
		binmode $self->{fh};
	}
	
	$cb->($self->{fh}) if $cb;
	return $self->{fh};
}


sub DESTROY {
	close delete $_[0]->{fh} if $_[0]->{fh};
	unlink delete $_[0]->{path} if ($_[0]->{path} and !($_[0]->{moved}));
}


my @chars = ('A'..'Z', 'a'..'z', 0..9);

sub _new {
	my ($self) = @_;
	
	$self->{path} = $HTTP::Server::EV::tmp_path.'/';
	$self->{path} .= @chars[rand @chars] for 1..50;
	
	$self->{name} = escape_filename($self->{name});
	$self->{name} =~s/\x{0}//g;
	
	unless( open ($self->{fh}, '+>', $self->{path}) ){
		warn __PACKAGE__." failed to create file - $! \n";
		$self->{parent_req}->drop;
		return;
	}
		
	$self->{parent_req}{parent_listener}{on_file_open}->( $self->{parent_req}, $self) 
		if $self->{parent_req}{parent_listener}{on_file_open};

}

sub _flush {
	my ($self, $data) = @_;
	
	$self->{size} += (syswrite($self->fh , $data ) or ($self->{parent_req}->drop and return));
	
	$self->{parent_req}{parent_listener}{on_file_write}->( $self->{parent_req}, $self, $data) 
				if $self->{parent_req}{parent_listener}{on_file_write};
}

sub _done {
	$_[0]->{parent_req}{parent_listener}{on_file_received}->($_[0]->{parent_req}, $_[0]) if $_[0]->{parent_req}{parent_listener}{on_file_received};
	
	$_[0]->{parent_req}->start;
	
	seek $_[0]->{fh},0,0;
}
