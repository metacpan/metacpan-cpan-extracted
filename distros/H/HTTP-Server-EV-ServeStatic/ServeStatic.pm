package HTTP::Server::EV::ServeStatic;
use utf8;
use strict;
use MIME::Types;

my $types = MIME::Types->new;

our $VERSION = '0.1';


=head1 NAME

HTTP::Server::EV::ServeStatic - Simple static file server. 

=head1 DESCRIPTION

Simple static file server for L<HTTP::Server::EV>. This module good for testing apps without frontend server. It's blocking and reads entire file into memory, so if you going to serve big files and need good performance - use frontend servers like nginx or lighttpd.

=head1 SYNOPSIS

	use HTTP::Server::EV;
	use HTTP::Server::EV::ServeStatic;
	
	my $static_server = HTTP::Server::EV::ServeStatic->new({
		basedir 		=> './html',
		indexes			=> [qw/index.html index.xhml default.html/],
		forbidden_ext	=> [qw/pm pl php conf ini/],
		rewrite_cb		=> sub {
			local($_) = @_;
			
			s/foo/bar/; # /path/foo/file.txt -> /path/bar/file.txt
			
			return $_;
		}
	});
	# or defaults
	my $static_server = HTTP::Server::EV::ServeStatic->new;
	
	
	HTTP::Server::EV->new->listen( 8080 , sub{
		my ($cgi) = @_;
		$static_server->serve($cgi); # try serve file. 
		
		# or give control to your app if file not found
		
		$cgi->header({ STATUS => '404 Not Found' });
		$cgi->print('404 - File not found');
	});
	
	EV::run;
	


=head1 METHODS

=head2 new( { options } )

=over

=item basedir

Directory with files. Dafault './'

=item indexes

Files to search for if no file specified in url. Arrayref. Default [qw/index.html/]

=item forbidden_ext

Don't serve files with those extensions. Arrayref. Default [qw/pm pl/]

=item rewrite_cb

Callback for rewriting uri before processing request. Gets uri as first arg and need to return new uri.

=back

=head2 serve( $http_server_ev_cgi_obj )

Process request

=cut







sub new {
	my ($pkgname, $self) = @_;
	
	$self->{basedir} //= '.';
	$self->{indexes} //= ['index.html'];
	$self->{forbidden_ext} //= [qw/pm pl/];
	
	if($self->{forbidden_ext}){
		$self->{forbidden}{$_} = 1 for @{$self->{forbidden_ext}};
	}
	
	bless $self, $pkgname;
}


sub serve { # self, cgi_obj
	my $path = $_[1]->{headers}{REQUEST_URI};
	
	$path = $_[0]->{rewrite_cb}->($path) if $_[0]->{rewrite_cb};
	
	$path =~s/\?.*$//g;
	$path =~s/\.\.+//g;
	$path =~s/[:<!>]//g;
	
	$path = $_[0]->_find_real_path($path) or return;
	
	$path =~m/\.([^.]*)$/;
	return if $_[0]->{forbidden}{$1};
	my $ext = $1;
	
	local( $/ ); # enable file slurp
	open( my $fh, '<', $path ) or return;
	binmode $fh;
	
		$_[1]->header({
			'Content-Type' => ( ($_ = $types->mimeTypeOf($ext)) ? $_->type : undef )
		});

		$_[1]->print(<$fh>);
		
	close $fh;
	
	$_[1]->next;
}
	


sub _find_real_path {
	my ($self, $path) = @_;
	
	if(-f ($self->{basedir}.$path) ){
		return $self->{basedir}.$path;
	}elsif( $self->{indexes} ){
		for ( @{ $self->{indexes} }){
			return $self->{basedir}.$path.'/'.$_ if( -f $self->{basedir}.$path.'/'.$_);
		}
	}
}