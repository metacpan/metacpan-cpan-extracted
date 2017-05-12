package TestServer;
use Data::Dump qw( dump );
use HTTP::Date;
use base ( 'Test::HTTP::Server::Simple', 'HTTP::Server::Simple::CGI' );

my %dispatch = (
    '/'                  => \&resp_root,
    '/hello'             => \&resp_hello,
    '/robots.txt'        => \&resp_robots,
    '/redirect/local'    => [ 307, '/target' ],
    '/redirect/loopback' => [ 307, 'http://127.0.0.1/hello' ],
    '/old/page'          => \&resp_old_page,
    '/size/big'          => \&resp_big_page,
    '/img/test'          => \&resp_img,
);

sub handle_request {
    my ( $self, $cgi ) = @_;

    #dump \%ENV;
    my $path = $cgi->path_info();

    #warn "path=$path";

    my $handler = $dispatch{$path};
    if ( ref $handler eq 'CODE' ) {
        print "HTTP/1.0 200 OK\r\n";
        $handler->($cgi);

    }
    elsif ( ref $handler eq 'ARRAY' ) {
        print "HTTP/1.0 $handler->[0]\r\n";
        print "Location: $handler->[1]\r\n";
    }
    elsif ( ref $handler eq 'HASH' ) {
        $handler->{code}->( $self, $cgi, $handler );
    }
    else {
        print "HTTP/1.0 404 Not found\r\n";
        print $cgi->header,
            $cgi->start_html('Not found'),
            $cgi->h1('Not found'),
            $cgi->end_html;
    }

}

sub resp_root {
    my $cgi = shift;
    print $cgi->header, $cgi->start_html,
        qq(<a href="#">recursive anchor</a>),
        qq(<a href="/">root</a>),
        qq(<a href="hello">follow me</a>),
        qq(<a href="nosuchlink">404</a>),
        qq(<a href="redirect/local">redirect local</a>),
        qq(<a href="redirect/loopback">redirect loopback</a>),
        qq(<a href="old/page">old and in the way</a>),
        qq(<a href="size/big">big file</a>),
        qq(<img src="img/test" />),
        $cgi->end_html;
}

sub resp_big_page {
    my $cgi = shift;
    print "Content-Length: 8192\r\n";
    print $cgi->header;
    print 'i am a really big file';

}

sub resp_img {
    my $cgi = shift;
    print $cgi->header('image/jpeg');
    print 'thisisanimage.heh';
}

sub resp_old_page {
    my $cgi = shift;
    printf( "Last-Modified: %s\r\n", time2str( time() - 86400 ) ); # yesterday
    print $cgi->header, $cgi->start_html, 'this page is old', $cgi->end_html;
}

sub resp_hello {
    my $cgi = shift;
    return if !ref $cgi;
    print $cgi->header, $cgi->h1('hello');
}

sub resp_robots {
    my $cgi = shift;
    print $cgi->header('text/plain'), '';                          # TODO
}

1;
