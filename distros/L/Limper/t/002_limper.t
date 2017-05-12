use Test::More;
use Limper;
use POSIX qw(setsid);
use strict;
use warnings;

if ($^O eq 'MSWin32') {
    plan skip_all => 'Tests fail randomly on MSWin32 - maybe just AMD?';
} else {
    eval { require Net::HTTP::Client };
    if ($@) {
        plan skip_all => 'Net::HTTP::Client not installed';
    } else {
        plan tests => 10;
    }
}

sub daemonize {
    chdir '/'                     or die "can't chdir to /: $!";
    open STDIN, '<', '/dev/null'  or die "can't read /dev/null: $!";
    open STDOUT, '>', '/dev/null' or die "can't write to /dev/null: $!";
    defined(my $pid = fork)       or die "can't fork: $!";
    return $pid if $pid;
    setsid != -1                  or die "Can't start a new session: $!";
    open STDERR, '>&', 'STDOUT'   or die "can't dup stdout: $!";
    0;
}

my ($port, $sock);

do {
    $port = int rand()*32767+32768;
    $sock = IO::Socket::INET->new(Listen => 5, ReuseAddr => 1, LocalAddr => 'localhost', LocalPort => $port, Proto => 'tcp')
            or warn "\n# cannot bind to port $port: $!";
} while (!defined $sock);
$sock->shutdown(2);
$sock->close();

my $pid = daemonize();
if ($pid == 0) {
    my $generic = sub { 'yay' };

    get '/' => $generic;
    post '/' => $generic;

    post qr{^/foo/} => sub {
        status 202, 'whatevs';
        headers Foo => ['bar', 'buzz'], 'Content-Type' => 'text/whee';
        'you posted something: ' . request->{body};
    };

    get '/baz' => sub {
        'your non-decoded query, if any: ' . request->{query};    # URIs of '/baz?fizz=buzz&foo=bar' now work
    };

    limp(LocalPort => $port);
    die;
} else {
    my $uri = "localhost:$port";
    sleep 1;

    my $res = Net::HTTP::Client->request(GET => "$uri/fizz");
    is $res->status_line, '404 Not Found', '404 status';
    is $res->content, 'This is the void', '404 body';

    $res = Net::HTTP::Client->request(HEAD => "$uri");
    is $res->status_line, '200 OK', '200 status';
    is $res->content, '', 'head no body';

    $res = Net::HTTP::Client->request(GET => "$uri/baz?fizz=buzz&foo=bar");
    is $res->status_line, '200 OK', '200 status';
    is $res->content, 'your non-decoded query, if any: fizz=buzz&foo=bar', 'query body';

    $res = Net::HTTP::Client->request(POST => "$uri/foo/bar", 'foo=bar');
    is $res->status_line, '202 whatevs', 'post status';
    is $res->content, 'you posted something: foo=bar', 'post body';
    is $res->header('Foo'), 'bar, buzz', 'Foo: bar';
    is $res->header('Content-Type'), 'text/whee', 'Content-Type: text/whee';
    kill -9, $pid;
}
