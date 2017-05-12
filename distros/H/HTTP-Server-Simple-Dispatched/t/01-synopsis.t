use strict;
use warnings;

use IO::File;
use Test::More;

BEGIN {
	eval q(require Test::HTTP);
	plan skip_all => "Test::HTTP required for these tests." if ($@);
	plan tests => 16;
}

use Test::HTTP;
use Test::HTTP::Syntax;


# The indenting is retarded because this is intended to be copied verbatim
# into the synopsis in the pod docs.

    use HTTP::Server::Simple::Dispatched qw(static);

    my $server = HTTP::Server::Simple::Dispatched->new(
      hostname => 'myawesomeserver.org',
      port     => 8081,
      debug    => 1,
      dispatch => [
        qr{^/hello/} => sub {
          my ($response) = @_;
          $response->content_type('text/plain');
          $response->content("Hello, world!");
          return 1;
        },
        qr{^/say/(\w+)/} => sub {
          my ($response) = @_;
          $response->content_type('text/plain');
          $response->content("You asked me to say $1.");
          return 1;
        },
        qr{^/counter/} => sub {
          my ($response, $request, $context) = @_;
          my $num = ++$context->{counter};
          $response->content_type('text/plain');
          $response->content("Called $num times.");
          return 1;
        },
        qr{^/static/(.*\.(?:png|gif|jpg))} => static("t/"),
        qr{^/error/} => sub {
          die "This will cause a 500!";
        },
      ],
    );

# here the similarity ends: the synopsis says run, we say background because
# we have to do some tests now.

#   $server->run();

my $pid = $server->background();
my $SERVER = 'http://localhost:8081';

test_http 'hello' {
	>> GET $SERVER/hello/

	<< 200
	<< Content-type: text/plain
	<< 
	<< Hello, world!
}

test_http 'say' {
	>> GET $SERVER/say/arglebargle/

	<< 200
	<<
	<< You asked me to say arglebargle.
}

test_http 'counter1' {
	>> GET $SERVER/counter/

	<< 200
	<<
	<< Called 1 times.
}

test_http 'counter2' {
	>> GET $SERVER/counter/

	<< 200
	<<
	<< Called 2 times.
}

test_http 'error' {
	>> GET $SERVER/error/

	<< 500
}

test_http '404' {
	>> GET $SERVER/clearly/not

	<< 404
}

test_http 'static' {
	my $fh = IO::File->new('t/test.png');
	my $content;
	{local $/; $content = <$fh>;}
	>> GET $SERVER/static/test.png

	<< 200
	<< Content-type: image/png
	
	ok($content eq $test->response->content, "File matches perfectly.");
	undef($fh);
}

test_http 'static_regex' {
	>> GET $SERVER/static/01-synopsis.t

	<< 404
}

test_http 'hax' {
	my $dots = "../" x 20;
	>> GET $SERVER/static/${dots}etc/passwd

	<< 404
}

kill TERM => $pid;
