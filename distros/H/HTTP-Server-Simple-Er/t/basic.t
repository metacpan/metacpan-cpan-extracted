#!/usr/bin/perl

use warnings;
use strict;

use Test::More qw(no_plan);

use HTTP::Server::Simple::Er;
my $port = 7779;
my $s = HTTP::Server::Simple::Er->new(port => $port,
  req_handler => sub {
    my $self = shift;
    my $path = $self->path;
    my $req  = $self->method;
    if($req eq 'POST' or $req eq 'PUT') {
      my $handle = $self->stdio_handle or die "bah";
      my $cl = $self->headers->content_length or die "ack";
      my $buf;
      read($handle, $buf, $cl) or die "gah";
      my ($foo) = map({s/.*=//; $_} grep({m/^foo=/} split(/\n/, $buf)));
      $self->output("You ${req}ed $foo.");
    }
    elsif($req eq 'GET') {
      if($path eq '/') {
        $self->output('<html>hi</html>');
      }
      elsif($path eq '/foo') {
        $self->output({content_type => 'text/plain'}, 'blah blah blah');
      }
      elsif($path eq '/echo') {
        $self->output({content_type => 'text/plain'}, `echo foo`);
      }
      else {
        $self->output(RC_NOT_FOUND => '<html>Sorry dude</html>');
      }
    }
    else {
      $self->output(500 => 'I cannot grant you that request.');
    }
  }
);
my $surl = $s->child_server;
is($surl, "http://localhost:$port");

use LWP::UserAgent;
my $agent = LWP::UserAgent->new;
{
  my $ans = $agent->get($surl);
  ok($ans->is_success, 'success') or
    die "Get failed: " . $ans->message;
  is($ans->protocol, 'HTTP/1.1');
  is($ans->content, '<html>hi</html>');
}
{
  my $ans = $agent->get($surl . '/foo');
  ok($ans->is_success, 'success') or die "Get failed: " . $ans->message;
  is($ans->content_type, 'text/plain');
  is($ans->content, 'blah blah blah');
}
if($^O eq 'linux') {
  my $ans = $agent->get($surl . '/echo');
  ok($ans->is_success, 'success') or die "Get failed: " . $ans->message;
  is($ans->content_type, 'text/plain');
  is($ans->content, "foo\n");
}
{
  my $ans = $agent->get($surl . '/bar');
  is($ans->code, 404);
  is($ans->message, 'Not Found');
  is($ans->protocol, 'HTTP/1.1');
  is($ans->content, '<html>Sorry dude</html>');
}
{
  my $ans = $agent->request(HTTP::Request->new(DELETE => $surl));
  is($ans->code, 500);
  is($ans->protocol, 'HTTP/1.1');
  is($ans->content, 'I cannot grant you that request.');
}
{
  my $ans = $agent->post($surl, {foo => 'bar'});
  ok($ans->is_success, 'success') or die "failed: " . $ans->message;
  is($ans->content, 'You POSTed bar.');
}
{
  my $ans = $agent->request(HTTP::Request::Common::PUT(
    $surl, Content => "foo=bar\n"));
  ok($ans->is_success, 'success') or die "failed: " . $ans->message;
  is($ans->content, 'You PUTed bar.');
}

#use YAML; die YAML::Dump($ans);

# vim:ts=2:sw=2:et:sta
