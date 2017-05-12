use strict;
no warnings;
use Socket;
use blib;
use utf8;






use Test::More tests => 30;
use AnyEvent::HTTP;
use HTTP::Request::Common;


BEGIN { use_ok('HTTP::Server::EV') };



my $server = HTTP::Server::EV->new;


my $last_req;
my @on_multipart_args;
my @on_file_open_args;
my @on_file_write_args;
my $on_file_write_data;
my @on_file_received_args;
my @on_error_args;

my @threading = eval { require Coro } ? ( threading => 1 ) : ();

$server->listen( 11111 , sub {
		my $cgi = shift;
		
		$cgi->attach(local *STDOUT); # attach STDOUT to socket
		
		$cgi->header; # print http headers to stdout
		
		print "Test page\n";
		# warn Dumper $cgi;
		
		$cgi->{buffer}->flush_wait();
		$last_req = $cgi;
		$last_req->close;	
	}, { 
		@threading,
		
		timeout => 2 , 
		
		on_multipart => sub {
			@on_multipart_args = @_;
			# called on multipart body receiving start
		},
		
		on_file_open => sub {
			@on_file_open_args = @_;
			# called on multipart file receiving start
		},
		
		on_file_write => sub {
			@on_file_write_args = @_;
			$on_file_write_data .= $_[2];
			# called when file part writed to disk. 
			# usefur for on flow calculting hashes like md5 
		},
		
		on_file_received => sub {
			@on_file_received_args = @_;
			# called on file writing done
		},
		
		on_error => sub {
			@on_error_args = @_;
			# called when server drops multipart post connection
		}
		
	});


my @async_tests;
sub call_next_test {
	(shift(@async_tests) or return )->() ; 
	
	$last_req = undef;
	@on_multipart_args = ();
	@on_file_open_args = ();
	@on_file_write_args = ();
	$on_file_write_data = '';
	@on_file_received_args = ();
	@on_error_args = ();
};

@async_tests = ( 

sub {
	print "\n------- GET\n";
	http_get 'http://127.0.0.1:11111/?utf8=test_%D1%82%D0%B5%D0%BA%D1%81%D1%82_utf8_%D1%82%D0%B5%D1%81%D1%82&cp1251=test_%F2%E5%EA%F1%F2_utf8_%F2%E5%F1%F2', sub {

		is( $_[0], "Test page\n", 'GET' );
		
		is( $last_req->{get}{utf8}, "test_текст_utf8_тест", 'GET param utf8' );
		is( $last_req->{get}{cp1251}, "test_текст_utf8_тест", 'GET param cp1251' );
		
		call_next_test;
	};
},

sub {
	http_get 'http://127.0.0.1:11111/'.('bigurl' x 1024), sub {
		ok( ( (!defined($last_req)) and (!defined($_[0])) ) , "GET url buffer overflow - conn dropped" );
		call_next_test;
	};
},


sub {
	http_post 'http://127.0.0.1:11111/', 
	'utf8=test_%D1%82%D0%B5%D0%BA%D1%81%D1%82_utf8_%D1%82%D0%B5%D1%81%D1%82&cp1251=test_%F2%E5%EA%F1%F2_utf8_%F2%E5%F1%F2',
	headers => {
		'Content-Type'	 => 'application/x-www-form-urlencoded'
	}, 
	sub {
		is( $_[0], "Test page\n", 'POST urlencoded' );
		is( $last_req->{post}{utf8}, "test_текст_utf8_тест", 'POST urlencoded param utf8' );
		is( $last_req->{post}{cp1251}, "test_текст_utf8_тест", 'POST urlencoded param cp1251' );
		
		call_next_test;
	};
},

sub {
	no utf8;
	use bytes;

		socket(my $socket, PF_INET, SOCK_STREAM, getprotobyname('tcp'));
		connect($socket, sockaddr_in( 11111 ,inet_aton( '127.0.0.1' ) ));binmode $socket;
		
		send ($socket,  q|POST testtesttest.....|, 0);
		
		$main::w = EV::io $socket, EV::READ, sub {
		
			is( read( $socket, $_, 1), 0 , 'timeout' );
			$main::w = undef;
			
			call_next_test;
		};
},

sub {
	http_request 
		DELETE => 'http://127.0.0.1:11111/', 
		headers => {
			'Connection' => 'close'
		},
			sub {
				is( $_[0], "Test page\n", 'DELETE (and any custom methods) reqest' );
				
				call_next_test;
			};
},


sub {
	print "\n------- POST\n";
	no utf8;
	use bytes;
	

	my $req = POST "", 
		Content_Type => 'form-data',
		Content      => [
			utf8   => 'test_текст_utf8_тест',
			cp1251 => 'test_текст_utf8_тест',
		];
	no bytes;
	use utf8;
		
		http_post 'http://127.0.0.1:11111/',
			$req->content,
			headers => {
				'Content-Type' => $req->header('Content-Type')
			},
		sub {
			is( $_[0], "Test page\n", 'POST multipart' );
			
			is( $last_req->{post}{utf8}, "test_текст_utf8_тест", 'POST multipart param utf8' );
			is( $last_req->{post}{cp1251}, "test_текст_utf8_тест", 'POST multipart param cp1251' );
			
			
			
			call_next_test;
		};
},

sub {
	no utf8;
	use bytes;
	my $req = POST "", 
		Content_Type => 'form-data',
		Content      => [
			('a' x 99999 )   => 'test_текст_utf8_тест',
			cp1251 => 'test_текст_utf8_тест',
		];
	no bytes;
	use utf8;
		http_post 'http://127.0.0.1:11111/',
			$req->content,
			headers => {
				'Content-Type' => $req->header('Content-Type')
			},
		sub {
			# use Data::Dumper;
			# warn Dumper(\@on_error_args);
			is( ref( @on_error_args[0]), 'HTTP::Server::EV::CGI' ,'POST on_error callback' );
			@on_error_args[0] = undef; # for ne
			call_next_test;
		};
},




sub {
	no utf8;
	use bytes;
	
	my $content = '1234567890' x (1024 * 1024); # 10mb file
	
	my $req = POST "", 
		Content_Type => 'form-data',
		Content      => [
			utf8   => 'test_текст_utf8_тест',
			cp1251 => 'test_текст_utf8_тест',
			
			file => [undef, '../.\..:<>utf8_файл'.chr(0).'.jpg', Content => $content],
		];
	no bytes;
	use utf8;
		
	my $not_skipped;
	
	SKIP: {
		print "\n----- HTTP::Server::EV::IO::AIO IO backend\n";
		
		eval "use HTTP::Server::EV::IO::AIO";
		skip('HTTP::Server::EV::IO::AIO not installed', 8) if $@;
		
		HTTP::Server::EV::IO::AIO->_use_me;
		
		$not_skipped = 1;
		
			http_post 'http://127.0.0.1:11111/',
				$req->content,
				headers => {
					'Content-Type' => $req->header('Content-Type')
				},
			sub {

				is( $last_req->{file}{file}{name} , ".._.__..___utf8_файл.jpg", 'POST multipart filename escape' );
				ok( $last_req->{file}{file}{size} == length($content) , 'POST multipart file size' );
				
				ok( @on_multipart_args[0] eq $last_req, 'POST on_multipart callback' );
				
				ok( (
						(@on_file_open_args[0] eq $last_req) and
						(@on_file_open_args[1] eq $last_req->{file}{file})
					)
				, 'POST on_file_open callback' );
				
				ok( (
						(@on_file_write_args[0] eq $last_req) and
						(@on_file_write_args[1] eq $last_req->{file}{file}) and 
						($on_file_write_data eq $content )
					)
				, 'POST on_file_write callback' );
				
				ok( (
						(@on_file_received_args[0] eq $last_req) and
						(@on_file_received_args[1] eq $last_req->{file}{file})
					)
				, 'POST on_file_received callback' );
				
				
				
				$last_req->{file}{file}->fh(sub {
					read $_[0], my $rcv_content, length($content)+1024;
					
					ok( $rcv_content eq $content , 'POST multipart file consistency' );
					
					$last_req->{file}{file}->save('./testfile', sub {
						ok( -e './testfile' , 'POST multipart file save' );
						
						call_next_test;
					});
				});
			};
	};
	
	call_next_test unless $not_skipped;
},




sub {
	print "\n----- HTTP::Server::EV::IO::Blocking IO backend\n";
	
	no utf8;
	use bytes;
	
	my $content = '123456789987654321' x 4096;
	
	my $req = POST "", 
		Content_Type => 'form-data',
		Content      => [
			utf8   => 'test_текст_utf8_тест',
			cp1251 => 'test_текст_utf8_тест',
			
			file => [undef, '../.\..:<>utf8_файл'.chr(0).'.jpg', Content => $content]
		];
	no bytes;
	use utf8;
		
	my $not_skipped;
	
	SKIP: {
		eval "use HTTP::Server::EV::IO::Blocking";
		
		HTTP::Server::EV::IO::Blocking->_use_me;
		
		$not_skipped = 1;
		
			http_post 'http://127.0.0.1:11111/',
				$req->content,
				headers => {
					'Content-Type' => $req->header('Content-Type')
				},
			sub {

				is( $last_req->{file}{file}{name} , ".._.__..___utf8_файл.jpg", 'POST multipart filename escape' );
				ok( $last_req->{file}{file}{size} == length($content) , 'POST multipart file size' );
				
				$last_req->{file}{file}->fh( sub {
					read $_[0], my $rcv_content, length($content)+1024;
					
				ok( $rcv_content eq $content , 'POST multipart file consistency' );
					
									ok( @on_multipart_args[0] eq $last_req, 'POST on_multipart callback' );
				
				ok( (
						(@on_file_open_args[0] eq $last_req) and
						(@on_file_open_args[1] eq $last_req->{file}{file})
					)
				, 'POST on_file_open callback' );
				
				ok( (
						(@on_file_write_args[0] eq $last_req) and
						(@on_file_write_args[1] eq $last_req->{file}{file}) and 
						($on_file_write_data eq $content )
					)
				, 'POST on_file_write callback' );
				
				ok( (
						(@on_file_received_args[0] eq $last_req) and
						(@on_file_received_args[1] eq $last_req->{file}{file})
					)
				, 'POST on_file_received callback' );
				
					
					
					$last_req->{file}{file}->save('./testfile', sub {
						ok( -e './testfile' , 'POST multipart file save' );
						
						call_next_test;
					});
				});
			};
	};
	
	call_next_test unless $not_skipped;
},


sub {
	unlink './testfile';
	rmdir $server->{tmp_path};
	exit 0;
}
);




call_next_test;

EV::run;