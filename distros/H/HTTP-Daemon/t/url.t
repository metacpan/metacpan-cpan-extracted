use strict;
use warnings;

use Test::More 0.98;

use Config;
use HTTP::Daemon;
use HTTP::Response;
use HTTP::Tiny 0.042;
use IO::Socket::IP 0.25;

my $can_fork
    = $Config{d_fork}
    || (($^O eq 'MSWin32' || $^O eq 'NetWare')
    and $Config{useithreads}
    and $Config{ccflags} =~ /-DPERL_IMPLICIT_SYS/);

plan skip_all => "This system cannot fork" if !$can_fork;

my $d = HTTP::Daemon->new or die "HTTP::Daemon->new: $!";

my $url = $d->url;
note "url: $url";

my $pid = fork;
die "fork: $!" if !defined $pid;

if ($pid == 0) {
    my $http = HTTP::Tiny->new(
        timeout => 3,
        proxy => undef,
        http_proxy => undef,
        https_proxy => undef,
    );
    my $res;
    eval {
        local $SIG{ALRM} = sub { die "alarm\n" };
        alarm 4;
        $res = $http->get($url);
    };
    my $err = $@;
    alarm 0;
    exit if $res && $res->{success};
    if ($err) {
        diag $err;
    }
    if ($res) {
        diag "$res->{status} $res->{reason}";
        diag $res->{content} if $res->{status} == 599;
    }
    exit 1;
}

my $c = $d->accept or die "accept: $!";
my $req = $c->get_request;
$c->send_response(HTTP::Response->new(200));
$c->close;
$d->close;

wait;
is $?, 0;

done_testing;
