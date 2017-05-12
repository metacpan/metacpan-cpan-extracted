package HTTP::Server::EV;
no warnings;

=head1 NAME

HTTP::Server::EV - Asynchronous HTTP server written in C with request parser. 

=head1 DESCRIPTION

HTTP::Server::EV - Asynchronous HTTP server using EV event loop. 
It doesn`t load files received in the POST request in memory as moust of CGI modules does, but stores them directly to tmp files, so it`s useful for handling large files without using a lot of memory. 

=head1 INCLUDED MODULES

L<HTTP::Server::EV::CGI> - received http request object

L<HTTP::Server::EV::MultipartFile> - received file object

L<HTTP::Server::EV::Buffer> - non blocking output

L<HTTP::Server::EV::BufTie> - workaround for correct handling requests in L<Coro> threads

L<HTTP::Server::EV::IO::AIO> - Non-blocking disk IO. 

L<HTTP::Server::EV::IO::Blocking> - Blocking IO.


=head1 SYNOPSIS

	use EV;
	use Coro;
	use HTTP::Server::EV;
	
	
	my $server = HTTP::Server::EV->new;
	
	$server->listen(90, sub {
		my $cgi = shift;
		
		$cgi->attach(*STDOUT);
		$cgi->header;

		print "Just another Perl server\n";
	});
	
	EV::run;


=cut


use EV;
use strict;
use Encode;
use Socket;
use utf8;
use Scalar::Util qw/weaken/;

use HTTP::Server::EV::CGI;
use HTTP::Server::EV::MultipartFile;
use HTTP::Server::EV::PortListener;


require Exporter;
*import = \&Exporter::import;
require DynaLoader;

$HTTP::Server::EV::VERSION = '0.69';
DynaLoader::bootstrap HTTP::Server::EV $HTTP::Server::EV::VERSION;

@HTTP::Server::EV::EXPORT = ();
@HTTP::Server::EV::EXPORT_OK = ();

our %listeners;
our $backend;





=head1 METHODS


=head2 new( { options } )
	
Options:

=over

=item tmp_path

Directory for saving received files. Tries to create if not found, dies on fail. 
Default: ./upload_tmpfiles/


=item cleanup_on_destroy

Usually HTTP::Server::EV::CGI deletes tmp files on DESTROY, but it might by bug if you delete HTTP::Server::EV::CGI object when its files are still opened. Setting on this flag causes HTTP::Server::EV delete all files in tmp_path on program close, but don`t use it if jou have several process working with same tmp dir.
Default: 0

=item backend

Seting on cause HTTP::Server::EV::CGI parse ip from X-Real-IP http header
Default: 0


=back

=cut




our $tmp_path;
our $instance;

sub new {
	my ($self, $params) = @_;
	
	return $instance if $instance;
	
	$params->{tmp_path} = './upload_tmpfiles/' unless($params->{tmp_path});
	unless(-d($params->{tmp_path})){
		mkdir($params->{tmp_path}) or die 'Can`t create dir for tmp files!';
	}
	$params->{tmp_path} =~ s|([^/])^|$1/|;
	
	$HTTP::Server::EV::tmp_path = $params->{tmp_path};
	
	$backend = $params->{backend};
	
	
	if(eval { require HTTP::Server::EV::IO::AIO }){
		HTTP::Server::EV::IO::AIO->_use_me;
	}else{
		require HTTP::Server::EV::IO::Blocking;
		HTTP::Server::EV::IO::Blocking->_use_me;
	}
	
	
	$instance = bless $params, $self;
	
}


=head2 listen( port num or IO::Socket::INET object , sub {req_received_callback} , { optional parameters and multipart processing callbacks })

Binds callback to port. Calls callback and passes L<HTTP::Server::EV::CGI> object in it. Returns L<HTTP::Server::EV::PortListener> obeject, you can keep it and use to stop port listening.


	$server->listen( 8080 , sub {
		my $cgi = shift;
		
		$cgi->attach(local *STDOUT); # attach STDOUT to socket
		
		$cgi->header; # print http headers to stdout
		
		print "Test page";
	});
	


	
	$server->listen( 8080 , sub {
		#req_received_callback
		my $cgi = shift;
		
		$cgi->attach(local *STDOUT); # attach STDOUT to socket
		
		$cgi->header; # print http headers to stdout
		
		print "Test page";
	}, { 
		threading => 1, # run every req_received_callback in Coro thread. "use Coro;" first
		
		timeout => 1*60 , # server drops request if there is no activity on socket after "timeout" sec. 1min default. Set 0 to disable
		#This is for not fully received requests, received requests aren't affected and you can keep request object with socket as long as you need it.
		
		fork_hook => sub {
			# do preforking here if you want. Forking more than 1 process per core may be inefficient if you app fully asynchronous. HTTP::Server::EV is fully asynchronous itself if uses IO::AIO
		},
		
		#multipart processing callbacks
		# you needn't specify all callbacks
		
		on_multipart => sub {
			my ($cgi) = @_;
			# called on multipart body receiving start
		},
		
		on_file_open => sub {
			my ($cgi, $multipart_file_obj ) = @_;
			# called on multipart file receiving start
		},
		
		on_file_write => sub {
			my ($cgi, $multipart_file_obj, $data_chunk ) = @_;
			# called when file part written to disk. 
			# useful for on flow calculting hashes like md5 
			# or just to know progress by reading  $multipart_file_obj->{size}
		},
		
		on_file_received => sub {
			my ($cgi, $multipart_file_obj) = @_;
			# called on file writing done
		},
		
		on_error => sub {
			my ($cgi) = @_;
			# called when server drops multipart post connection. 
			# also called when you manually reject connection by calling $cgi_obj->drop;
		},
		
	});
	


=cut


	
sub listen {
	my ($self, $socket, $cb, $params) = @_;
	
	die "You can`t bind two listeners on one port!\n" if $HTTP::Server::EV::listeners{$socket};
	
	if(int($socket) eq $socket){
		$params->{port} = $socket;
	}else {
		$params->{socket} = $socket;
	}
	$params->{cb} = $cb;
	

	$HTTP::Server::EV::listeners{$socket} = HTTP::Server::EV::PortListener->new($params);
};





=head2 cleanup

Delete all files in tmp_path. Automatically called on DESTROY if cleanup_on_destroy set

=cut


sub cleanup {
	my @files = glob ($_[0]->{tmp_path}.'*');
	unlink $_ for (@files);
}

sub DESTROY {
	$_[0]->cleanup if($_[0]->{cleanup_on_destroy});
}

sub dl_load_flags {0}; # Prevent DynaLoader from complaining and croaking


=head1 WARNINGS

Static allocated buffers:


- 4kb for GET/POST form field names

- 4kb for GET values

- 50kb for POST form field values ( not for files. Files are stored into tmp directly from socket stream, so filesize not limited by HTTP::Server::EV)

HTTP::Server::EV drops connection if some buffer overflows. You can change these values in EV.xs and recompile module.


=head1 COPYRIGHT AND LICENSE

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
