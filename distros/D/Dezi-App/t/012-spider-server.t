#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 4;
use HTTP::Date;
use Try::Tiny;
use Class::Load;

my $num_tests = 4;

SKIP: {

    my @required = qw(
        Dezi::Aggregator::Spider
        Test::HTTP::Server::Simple
        HTTP::Server::Simple::CGI
        HTTP::Server::Simple::Authen
    );
    for my $cls (@required) {
        diag("Checking on $cls");
        my $missing;
        my $loaded = try {
            Class::Load::load_class($cls);
        }
        catch {
            warn $_;
            if ( $_ =~ m/Can't locate (\S+)/ ) {
                $missing = $1;
                $missing =~ s/\//::/g;
                $missing =~ s/\.pm//;
            }
            return 0;
        };
        if ( !$loaded ) {
            if ($missing) {
                diag( '-' x 40 );
                diag("Do you need to install $missing ?");
                diag( '-' x 40 );
            }
            skip "$cls required for spider test", $num_tests;
            last;
        }
    }

    # define our test server
    {

        package MyAuth;
        use strict;

        sub new { return bless {} }

        sub authenticate {
            my ( $self, $user, $pass ) = @_;
            return $user eq 'foo' && $pass eq 'bar';
        }

        package MyServer;
        use Data::Dump qw( dump );
        use HTTP::Date;
        @MyServer::ISA = (
            'Test::HTTP::Server::Simple', 'HTTP::Server::Simple::Authen',
            'HTTP::Server::Simple::CGI'
        );

        my %dispatch = (
            '/'                  => \&resp_root,
            '/hello'             => \&resp_hello,
            '/robots.txt'        => \&resp_robots,
            '/secret'            => { code => \&resp_secret },
            '/secret/more'       => \&resp_hello,
            '/redirect/local'    => [ 307, '/target' ],
            '/redirect/loopback' => [ 307, 'http://127.0.0.1/hello' ],
            '/old/page'          => \&resp_old_page,
            '/size/big'          => \&resp_big_page,
            '/img/test'          => \&resp_img,
            '/sitemap.xml'       => \&sitemap,
            '/redirect/elsewhere' =>
                [ 307, 'http://somewherefaraway.net/donotfollow' ],
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
                qq(<a href="sitemap.xml">sitemap</a>),
                qq(<a href="secret">secret</a>),
                qq(<a href="nosuchlink">404</a>),
                qq(<a href="far/too/deep/to/reach">depth</a>),
                qq(<a href="http://somewhereelse.net/donotfollow">external link</a>),
                qq(<a href="redirect/local">redirect local</a>),
                qq(<a href="redirect/loopback">redirect loopback</a>),
                qq(<a href="redirect/elsewhere">redirect elsewhere</a>),
                qq(<a href="old/page">old and in the way</a>),
                qq(<a href="size/big">big file</a>),
                qq(<a href="skip-me/bad-pattern">FileRules skip</a>),
                qq(<a href="skip-me/bad?query=pass">FileRules skip</a>),
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
            printf( "Last-Modified: %s\r\n", time2str( time() - 86400 ) )
                ;    # yesterday
            print $cgi->header, $cgi->start_html, 'this page is old',
                $cgi->end_html;
        }

        sub resp_hello {
            my $cgi = shift;
            return if !ref $cgi;
            print $cgi->header, $cgi->h1('hello');
        }

        sub resp_robots {
            my $cgi = shift;
            print $cgi->header('text/plain'), '';    # TODO
        }

        sub authen_handler {
            return MyAuth->new();
        }

        sub resp_secret {
            my $self    = shift;
            my $cgi     = shift;
            my $handler = shift;

            if ( !$self->authenticate ) {
                print $cgi->header;
                print 'permission denied';
            }
            else {
                print "HTTP/1.0 200 OK\r\n";
                print $cgi->header, $cgi->start_html,
                    qq(<a href="secret/more">more secret</a>),
                    $cgi->end_html;
            }
        }

        sub sitemap {
            my $cgi = shift;

            my $base = $cgi->url();

            print "Content-Type: application/xml\n\n";

            my $now = HTTP::Date::time2iso( time() );
            $now =~ s/ /T/;
            my $yesterday = HTTP::Date::time2iso( time() - 86400 );
            $yesterday =~ s/ /T/;

            print <<XML;
<?xml version="1.0" encoding="UTF-8"?>
<urlset	xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	    xsi:schemaLocation="http://www.sitemaps.org/schemas/sitemap/0.9 http://www.sitemaps.org/schemas/sitemap/0.9/sitemap.xsd"
	    xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">

	<url>
		<loc>$base/hello</loc> 
		<lastmod>$now+00:00</lastmod> 
		<changefreq>weekly</changefreq> 
		<priority>0.6</priority>
	</url>
	<url>
		<loc>$base/nosuchlink</loc> 
		<lastmod>$yesterday+00:00</lastmod> 
		<changefreq>daily</changefreq> 
		<priority>0.6</priority>
	</url>
	<url>
		<loc>http://elsewhere.foo/bar</loc> 
		<lastmod>$yesterday+00:00</lastmod> 
		<changefreq>hourly</changefreq> 
		<priority>0.6</priority>
	</url>
</urlset>
XML

        }
    }

    use_ok('Dezi::Test::Indexer');

    my $port     = 5002;
    my $server   = MyServer->new($port);
    my $base_uri = $server->started_ok('start http server');
    if ( !$base_uri ) {
        die "server failed to start";
    }
    my $debug = $ENV{DEZI_DEBUG} || 0;

    ok( my $spider = Dezi::Aggregator::Spider->new(
            verbose => $debug,
            debug   => $debug,
            email   => 'noone@swish-e.org',
            agent   => 'swish-prog-test',

            #max_depth => 2, # unlimited

            file_rules => [
                'filename contains bad-pattern',

                #'filename contains \?',    # anything with query string
                'filename contains \?.*query=pass',    # specific query param
            ],

            # hurry up and fail
            delay => 0,

            filter => sub {
                $debug and diag( "doc filter on " . $_[0]->url );
                $debug and diag( "body:" . $_[0]->content );
            },
            credentials    => 'foo:bar',
            same_hosts     => ["127.0.0.1"],
            modified_since => time2str( time() ),
            max_size       => 4096,
        ),
        "new spider"
    );

    diag( "spidering " . $base_uri );
    is( $spider->crawl($base_uri), 5, "crawl" );

}
