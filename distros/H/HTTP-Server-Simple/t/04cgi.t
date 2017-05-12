# -*- perl -*-

use Test::More;
use Socket;
use strict;

my $PORT = 40000 + int(rand(10000));

my $host = gethostbyaddr(inet_aton('localhost'), AF_INET);

my %methods=(
              url => "url: http://$host:".$PORT,
              path_info => 'path_info: /cgitest/path_info',
              server_name => "server_name: $host",
              server_port => 'server_port: '.$PORT,
              server_software => 'server_software: HTTP::Server::Simple/\d+.\d+',
              request_method => 'request_method: GET',
              raw_cookie => undef, # do not test
            );

my %envvars=(
              SERVER_URL => "SERVER_URL: http://$host:".$PORT.'/',
              SERVER_PORT => 'SERVER_PORT: '.$PORT,
              REQUEST_METHOD => 'REQUEST_METHOD: GET',
              REQUEST_URI => 'REQUEST_URI: /cgitest/REQUEST_URI',
              SERVER_PROTOCOL => 'SERVER_PROTOCOL: HTTP/1.1',
              SERVER_NAME => "SERVER_NAME: $host",
              SERVER_SOFTWARE => 'SERVER_SOFTWARE: HTTP::Server::Simple/\d+.\d+',
              REMOTE_ADDR => 'REMOTE_ADDR: 127.0.0.1',
              QUERY_STRING => 'QUERY_STRING: ',
              PATH_INFO => 'PATH_INFO: /cgitest/PATH_INFO',
            );

if ($^O eq 'freebsd' && `sysctl -n security.jail.jailed` == 1) {
    delete @methods{qw(url server_name)};
    delete @envvars{qw(SERVER_URL SERVER_NAME REMOTE_ADDR)};
    plan tests => 47;
}
else {
    plan tests => 62;
}

{
  my $server=CGIServer->new($PORT);
  is($server->port(),$PORT,'Constructor set port correctly');
  sleep(3); # wait just a moment

  my $pid=$server->background;

  like($pid, '/^-?\d+$/', 'pid is numeric');

  select(undef,undef,undef,0.2); # wait a sec
  my @message_tests = (
      [["GET / HTTP/1.1",""], '/NOFILE/', '[GET] no file'],
      [["POST / HTTP/1.1","Content-Length: 0",""], '/NOFILE/', '[POST] no file'],
      [["HEAD / HTTP/1.1",""], '/NOFILE/', '[HEAD] no file'],
      [["PUT / HTTP/1.1","Content-Length: 0",""], '/NOFILE/', '[PUT] no file'],
      [["DELETE / HTTP/1.1",""], '/NOFILE/', '[DELETE] no file'],
      [["PATCH / HTTP/1.1","Content-Length: 0",""], '/NOFILE/', '[PATCH] no file'],
      [["OPTIONS / HTTP/1.1","Content-Length: 0",""], '/NOFILE/', '[OPTIONS] no file'],
  );
  foreach my $message_test (@message_tests) {
    my ($message, $expected, $description) = @$message_test;
    like(fetch(@$message), $expected, $description);
    select(undef,undef,undef,0.2); # wait a sec
  }

  foreach my $method (keys(%methods)) {
    next unless defined $methods{$method};
    like(
          fetch("GET /cgitest/$method HTTP/1.1",""),
          "/$methods{$method}/",
          "method - $method"
        );
    select(undef,undef,undef,0.2); # wait a sec
  }

  foreach my $envvar (keys(%envvars)) {
    like(
          fetch("GET /cgitest/$envvar HTTP/1.1",""),
          "/$envvars{$envvar}/",
          "Environment - $envvar"
        );
    select(undef,undef,undef,0.2); # wait a sec
  }

# extra tests for HTTP/1.1 absolute URLs

  foreach my $verb ('GET', 'HEAD') {
    foreach my $method (keys(%methods)) {
      next unless defined $methods{$method};

      my $method_value = $methods{$method};
      $method_value =~ s/\bGET\b/$verb/;

      like(
            fetch("$verb http://localhost/cgitest/$method HTTP/1.1",""),
            "/$method_value/",
            "method (absolute URL) - $method"
          );
      select(undef,undef,undef,0.2); # wait a sec
    }

    foreach my $envvar (keys(%envvars)) {
      (my $envvar_value = $envvars{$envvar});
      $envvar_value =~ s/\bGET\b/$verb/;

      like(
            fetch("$verb http://localhost/cgitest/$envvar HTTP/1.1",""),
            "/$envvar_value/",
            "Environment (absolute URL) - $envvar"
          );
      select(undef,undef,undef,0.2); # wait a sec
    }
  }

  like(
       fetch("GET /cgitest/REQUEST_URI?foo%3Fbar HTTP/1.0",""),
       qr/foo%3Fbar/,
       "Didn't decode already"
      );

  like(
       fetch("GET /cgitest/foo%2Fbar/PATH_INFO HTTP/1.0",""),
       qr|foo/bar|,
       "Did decode already"
      );

  like(
      fetch("GET /cgitest/raw_cookie HTTP/1.0","Cookie: foo=bar",""),
      qr|foo=bar|,
      "uses HTTP_COOKIE",
  );

  like(
      fetch("GET /cgitest/raw_cookie HTTP/1.0",
            "Cookie: foo=bar\r\nCookie: baz=qux",""),
      qr|foo=bar[;,] baz=qux|,
      "combines multiple cookies into HTTP_COOKIE"
  );

  is(kill(9,$pid),1,'Signaled 1 process successfully');
  wait or die "counldn't wait for sub-process completion";
}


sub fetch {
    my $hostname = "localhost";
    my $port = $PORT;
    my $message = join "", map { "$_\015\012" } @_;
    my $timeout = 5;    
    my $response;        
    
    eval {
        local $SIG{ALRM} = sub { die "early exit - SIGALRM caught" };
        alarm $timeout*2; #twice longer than timeout used later by select()  
 
        my $iaddr = inet_aton($hostname) || die "inet_aton: $!";
        my $paddr = sockaddr_in($port, $iaddr) || die "sockaddr_in: $!";
        my $proto = getprotobyname('tcp') || die "getprotobyname: $!";
        socket(SOCK, PF_INET, SOCK_STREAM, $proto) || die "socket: $!";
        connect(SOCK, $paddr) || die "connect: $!";
        (send SOCK, $message, 0) || die "send: $!";
        
        my $rvec = '';
        vec($rvec, fileno(SOCK), 1) = 1;
        die "vec(): $!" unless $rvec; 

        $response = '';
        for (;;) {        
            my $r = select($rvec, undef, undef, $timeout);
            die "select: timeout - no data to read from server" unless ($r > 0);
            my $l = sysread(SOCK, $response, 1024, length($response));
            die "sysread: $!" unless defined($l);
            last if ($l == 0);
        }
        $response =~ s/\015\012/\n/g; 
        (close SOCK) || die "close(): $!";
        alarm 0;
    }; 
    if ($@) {
      	return "[ERROR] $@";
    }
    else {
        return $response;
    }    
}

{
  package CGIServer;
  use base qw(HTTP::Server::Simple::CGI);

  sub handle_request {
    my $self=shift;
    my $cgi=shift;


    my $file=(split('/',$cgi->path_info))[-1]||'NOFILE';
    $file=~s/\s+//g;
    $file||='NOFILE';
    print "HTTP/1.0 200 OK\r\n";    # probably OK by now
    print "Content-Type: text/html\r\nContent-Length: ";
    my $response;
    if(exists $methods{$file}) {
      $response = "$file: ".$cgi->$file();
    } elsif($envvars{$file}) {
      $response="$file: $ENV{$file}";
    } else {
      $response=$file;
    }
    print length($response), "\r\n\r\n", $response;
  }
}


