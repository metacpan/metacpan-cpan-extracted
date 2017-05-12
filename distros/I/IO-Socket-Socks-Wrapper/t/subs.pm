use IO::Socket::INET;
use IO::Socket::Socks qw/:constants $SOCKS_ERROR/;

sub make_socks_server($;$$) {
	my ($version, $delay) = @_;
	
	my $old_socket_class = $IO::Socket::Socks::SOCKET_CLASS;
	$IO::Socket::Socks::SOCKET_CLASS = 'IO::Socket::INET';
	
	my $serv = IO::Socket::Socks->new(Listen => 3, SocksVersion => $version)
		or die $@;
	
	my $child = fork();
	die 'fork: ', $! unless defined $child;
	
	if ($child == 0) {
		my $connections_processed = 0;
		my $need_to_fail;
		local $SIG{TERM} = sub { exit $connections_processed };
		local $SIG{USR1} = sub { $need_to_fail = !$need_to_fail };
		
		while (1) {
			my $client = $serv->accept()
				or next;
			
			$connections_processed++;
			
			my $subchild = fork();
			die 'subfork: ', $! unless defined $subchild;
			
			if ($subchild == 0) {
				my ($cmd, $host, $port) = @{$client->command()};
				
				if($cmd == CMD_CONNECT)
				{ # connect
					my $socket = !$need_to_fail ? IO::Socket::INET->new(PeerHost => $host, PeerPort => $port, Timeout => 10) : undef;
					
					if($socket)
					{
						# request granted
						sleep $delay if $delay;
						$client->command_reply($version == 4 ? REQUEST_GRANTED : REPLY_SUCCESS, $socket->sockhost, $socket->sockport);
					}
					else
					{
						# request rejected or failed
						$client->command_reply($version == 4 ? REQUEST_FAILED : REPLY_HOST_UNREACHABLE, $host, $port);
						$client->close();
						exit;
					}
					
					my $selector = IO::Select->new($socket, $client);
					
					MAIN_CONNECT:
					while(1)
					{
						my @ready = $selector->can_read();
						foreach my $s (@ready)
						{
							my $readed = $s->sysread(my $data, 1024);
							unless ($readed)
							{
								# error or socket closed
								$socket->close();
								last MAIN_CONNECT;
							}
							
							if($s == $socket)
							{
								# return to client data readed from remote host
								$client->syswrite($data);
							}
							else
							{
								# return to remote host data readed from the client
								$socket->syswrite($data);
							}
						}
					}
				}
				
				exit;
			}
		}
	}
	
	$IO::Socket::Socks::SOCKET_CLASS = $old_socket_class;
	return ($child, $serv->sockhost eq "0.0.0.0" ? "127.0.0.1" : $serv->sockhost, $serv->sockport);
}

sub make_http_server {
	my $serv = IO::Socket::INET->new(Listen => 3)
		or die $@;
	
	my $child = fork();
	die 'fork: ', $! unless defined $child;
	
	if ($child == 0) {
		while (1) {
			my $client = $serv->accept()
				or next;
			
			my $buf;
			while (1) {
				$client->sysread($buf, 1024, length $buf)
					or last;
				if (rindex($buf, "\015\012\015\012") != -1) {
					last;
				}
			}
			
			my ($path) = $buf =~ /GET\s+(\S+)/
				or next;
			
			my $response;
			if ($path eq '/') {
				$response = 'ROOT';
			}
			elsif ($path eq '/index') {
				$response = 'INDEX';
			}
			else {
				$response = 'UNKNOWN';
			}
			
			$client->syswrite(
				join(
					"\015\012",
					"HTTP/1.1 200 OK",
					"Connection: close",
					"Content-Type: text/html",
					"\015\012"
				) . $response
			);
		}
		
		exit;
	}
	
	return ($child, $serv->sockhost eq "0.0.0.0" ? "127.0.0.1" : $serv->sockhost, $serv->sockport);
}

sub make_ftp_server {
	my $serv = IO::Socket::INET->new(Listen => 3)
		or die $@;
		
	my $child = fork();
	die 'fork: ', $! unless defined $child;
	
	if ($child == 0) {
		while (1) {
			my $client = $serv->accept()
				or next;
			
			$client->syswrite("220 Fake FTP Server\015\012");
			my $buf;
			$client->sysread($buf, 1024);
			my ($user) = $buf =~ /USER (\S+)/ or next;
			$client->syswrite("331 please send the PASS\015\012");
			$client->sysread($buf, 1024);
			my ($password) = $buf =~ /PASS (\S+)/ or next;
			if ($user eq 'root' && $password eq 'toor') {
				$client->syswrite("230 welcome\015\012");
			}
			else {
				$client->syswrite("530 incorrect password or account name\015\012");
			}
		}
		
		exit;
	}
	
	return ($child, $serv->sockhost eq "0.0.0.0" ? "127.0.0.1" : $serv->sockhost, $serv->sockport);
}

1;
