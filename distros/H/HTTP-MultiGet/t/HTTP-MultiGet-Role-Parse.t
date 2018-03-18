use Modern::Perl;
use Log::LogMethods::Log4perlLogToString;
use Test::More qw(no_plan);
use HTTP::Response;
use HTTP::Headers;
use HTTP::Request;
use Data::Dumper;
use AnyEvent::Loop;
use Scalar::Util qw(looks_like_number);
use AnyEvent::Strict;
use Carp qw(confess);
BEGIN { $SIG{__DIE__} = sub { confess @_ }; }

my $string;
my $module='HTTP::MultiGet::Role';
require_ok($module);
use_ok($module);
my $class='SomeTestClass';
my $log=LoggerToString($class,$string);

my $self=test->new;

$self->agent->on_create_request_cb(\&handle_response);

isa_ok($self,'test');

our @RESP=();

sub handle_response {
  my ($id,$req)=@_;
  my $res=shift @RESP;
  $req->respond_with($res->content,{$res->headers->flatten});
}

{
  my $code=200;
  my $msg='OK';
  my $body='{"test":"ok"}';
  my $header=new HTTP::Headers(Status=>$code);
  my $res=new HTTP::Response($code,$msg,$header,$body);
  push @RESP,$res;

  my $result=$self->test;
  ok($result,'Should have a true result');
  isa_ok($result,'Data::Result');
  is_deeply($result->get_data,{qw(test ok)},'result strcture test');
}
{
  my $code=400;
  my $msg='ERROR';
  my $body='{"test":"ok"}';
  my $header=new HTTP::Headers(Status=>$code);
  my $res=new HTTP::Response($code,$msg,$header,$body);
  push @RESP,$res;

  my $result=$self->test;
  ok(!$result,'Should have a false result');
  isa_ok($result,'Data::Result');
  like($result,qr/$body/,'result string test');
}

BEGIN {
  package
    test;
  
  use Modern::Perl;
  use Moo;
  BEGIN {with 'HTTP::MultiGet::Role' }

  sub que_test {
    my ($self,$cb,@args)=@_;
    $self->queue_request(HTTP::Request->new(GET=>'http://somewhere.com'),$cb);
  }
}
