#!/usr/bin/env perl
use Test::More;
use Jenkins::NotificationListener;
use AE;
use AnyEvent::Socket;
use Time::HiRes qw(usleep);

my $cv = AnyEvent->condvar;

my $server = Jenkins::NotificationListener->new( host => undef , port => 8888 , on_notify => sub {
    my $payload = shift;   # Jenkins::Notification;
    $cv->send;
    ok $payload;
    is $payload->status, 'FAILED';
    is $payload->phase, 'STARTED';
    isa_ok $payload->job, 'Net::Jenkins::Job';
    isa_ok $payload->build, 'Net::Jenkins::Job::Build';

})->start();

tcp_connect "localhost", 8888, sub {
    my ($fh) = @_
        or die "localhost failed: $!";
    ok $fh;
    print $fh <<'JSON';
{
    "name": "jruby-git",
    "url": "job/jruby-git",
    "build":{
        "number": 4259,
        "phase": "STARTED",
        "status": "FAILED",
        "url": "/job/jruby-git/4259",
        "full_url": "http://ci.jruby.org/job/jruby-git/4259",
        "parameters":{
            "branch":"master"
        }
    }
}
JSON

    # enjoy your filehandle
};

$cv->recv;
done_testing;
