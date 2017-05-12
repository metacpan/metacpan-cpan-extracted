#!/usr/bin/perl

use lib "t/lib";

use strict;
use warnings;

use Test::More;
use Test::Exception;
use Carp qw(croak);
use URI;

eval "use Test::M3::ServerView::TestServer";
plan skip_all => "Can't test HTTP stuff since server won't load" if $@;

plan tests => 13;

require M3::ServerView;

my $s = Test::M3::ServerView::TestServer->new();
my $uri = $s->started_ok("Test::M3::ServerView::TestServer up and running on port " . $s->port);
my $conn = M3::ServerView->connect_to($uri);

no warnings 'redefine';

my $query_echo = "";
local *M3::ServerView::_get_page_contents = sub {
    my ($self, $uri) = @_;

    my $ua = LWP::UserAgent->new;
    my $req = HTTP::Request->new(GET => $uri);
    
    my $user = $self->user;
    my $password = $self->password;

    if (defined $user && defined $password) {
        $req->authorization_basic($user, $password);
    }
    
    my $t = time;
    
    my $res = $ua->request($req);
    unless ($res->is_success) {
        croak "Failed to get '$uri' because server returned: ", $res->status_line;
    }
    $query_echo = $res->header("X-EchoQuery");
    return wantarray ? ($res->content, time - $t) : $res->content;
};

$query_echo = "";
my $view = $conn->find_jobs({});
like($query_echo, qr/\bfind=Find\b/);

$query_echo = "";
$view = $conn->find_jobs({ user => "Foo" });
like($query_echo, qr/\bfind=Find\b/);
like($query_echo, qr/\bowner=Foo\b/);

$query_echo = "";
$view = $conn->find_jobs({ batch_job_number => 10 });
like($query_echo, qr/\bbjno=10\b/);

$query_echo = "";
$view = $conn->find_jobs({ name => "Bar" });
like($query_echo, qr/\bname=Bar\b/);

$query_echo = "";
$view = $conn->find_jobs({ queued => 2 });
like($query_echo, qr/\bqueued=on\b/);

$query_echo = "";
$view = $conn->find_jobs({ type => "B" });
like($query_echo, qr/\btype=B\b/);

$query_echo = "";
$view = $conn->find_jobs({ user => "is space" });
like($query_echo, qr/\bowner=is\+space\b/);

$query_echo = "";
$view = $conn->find_jobs({ user => "Foo", queued => 1, type => "I" });
like($query_echo, qr/\bfind=Find\b/);
like($query_echo, qr/\bowner=Foo\b/);
like($query_echo, qr/\bqueued=on\b/);
like($query_echo, qr/\btype=I\b/);
