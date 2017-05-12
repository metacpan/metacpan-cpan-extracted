use IO::Socket::Socks qw/:constants $SOCKS_ERROR/;
use IO::Socket;
use IO::Select;
use strict;

sub make_socks_server {
	my ($version, $login, $password, %delay) = @_;
	
	my $serv = IO::Socket::Socks->new(Listen => 3, SocksVersion => $version, RequireAuth => ($login && $password), UserAuth => sub {
		$login = ''    unless defined $login;
		$password = '' unless defined $password;
		$_[0] = '' unless defined $_[0];
		$_[1] = '' unless defined $_[1];
		return $_[0] eq $login && $_[1] eq $password;
	}) or die $@;
	
	my $child = fork();
	die 'fork: ', $! unless defined $child;
	
	if ($child == 0) {
		while (1) {
			if ($delay{accept}) {
				sleep $delay{accept};
			}
			
			my $client = $serv->accept()
				or next;
				
			my $subchild = fork();
			die 'subfork: ', $! unless defined $subchild;
			
			if ($subchild == 0) {
				my ($cmd, $host, $port) = @{$client->command()};

				if($cmd == CMD_CONNECT)
				{ # connect
					my $socket = IO::Socket::INET->new(PeerHost => $host, PeerPort => $port, Timeout => 10);
					if ($delay{reply}) {
						sleep $delay{reply};
					}
					if($socket)
					{
						# request granted
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
							unless($readed)
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
	
	return ($child, fix_addr($serv->sockhost), $serv->sockport);
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
			
			my $subchild = fork();
			die 'subfork: ', $! unless defined $subchild;
			
			if ($subchild == 0) {
				my $buf;
				while (1) {
					$client->sysread($buf, 1024, length $buf)
						or last;
					if (rindex($buf, "\015\012\015\012") != -1) {
						last;
					}
				}
				
				my ($path) = $buf =~ /GET\s+(\S+)/
					or exit;
				
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
				
				exit;
			}
		}
		
		exit;
	}
	
	return ($child, fix_addr($serv->sockhost), $serv->sockport);
}

sub fix_addr {
	return '127.0.0.1' if $_[0] eq '0.0.0.0';
	return '0:0:0:0:0:0:0:1' if $_[0] eq '::';
	return $_[0];
}

1;
