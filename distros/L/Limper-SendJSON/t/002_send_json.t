use Test::More;
use Limper::SendJSON;
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
        plan tests => 9;
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

    get '/foo' => sub {
        send_json { foo => 'bar' };
    };

    get '/pretty' => sub {
        send_json { foo => 'bar' }, pretty => 1;
    };

    get '/fizz' => sub {
        send_json bless { fizz => 'buzz' }, 'fizzy';
    };

    limp(LocalPort => $port);
    die;
} else {
    my $uri = "localhost:$port";
    sleep 1;

    my $res = Net::HTTP::Client->request(GET => "$uri/foo");
    is $res->status_line, '200 OK', 'foo status';
    is $res->content, '{"foo":"bar"}', 'foo body';
    is $res->header('Content-Type'), 'application/json', 'Content-Type: application/json';

    $res = Net::HTTP::Client->request(GET => "$uri/pretty");
    is $res->status_line, '200 OK', 'pretty status';
    is $res->content, "{\n   \"foo\" : \"bar\"\n}\n", 'pretty body';
    is $res->header('Content-Type'), 'application/json', 'Content-Type: application/json';

    $res = Net::HTTP::Client->request(GET => "$uri/fizz");
    is $res->status_line, '500 Internal Server Error', 'fizz status';
    is $res->content, 'Internal Server Error', 'fizz body';
    is $res->header('Content-Type'), 'text/plain', 'Content-Type: text/plain';

    kill -9, $pid;
}
