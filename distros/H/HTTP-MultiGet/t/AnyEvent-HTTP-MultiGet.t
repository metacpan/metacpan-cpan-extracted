use Modern::Perl;
use Log::LogMethods::Log4perlLogToString;
use Carp qw(confess);
use Data::Dumper;
use AnyEvent::Loop;
BEGIN { $SIG{__DIE__} = sub { confess @_ }; }
use Test::More qw(no_plan);

my $class='AnyEvent::HTTP::MultiGet';
require_ok($class);
use_ok($class);

my $string;
my $logger=LoggerToString($class,$string);
my $self=$class->new(logger=>$logger,request_opts=>{timeout=>10,persistent=>0,cookie_jar=>{},keepalive=>0});
isa_ok($self,$class);

SKIP: { skip 'env valirable RUN_HTTP_TESTS not set', 56 unless $ENV{RUN_HTTP_TESTS};
if(0){
my $count=0;
TEST_LOOP: {
  my $req=HTTP::Request->new(GET=>'https://google.com');
  my @todo=HTTP::Request->new(GET=>'https://yahoo.com');
  push @todo,HTTP::Request->new(GET=>'https://news.com');
  push @todo,HTTP::Request->new(GET=>'https://127.0.0.1:5888');

  my $code;
  $code=sub {
    my ($obj,$request,$result)=@_;
    diag sprintf 'HTTP Response code: %i %s',$result->code,$request->uri;
    ++$count;
    if(my $next=shift @todo) {
      $self->add_cb($next,$code);
      $self->run_next;
    }
    diag $count;
    no warnings;
    last TEST_LOOP if $count==4;
  };
  $self->add_cb($req,$code);
  $self->run_next;
  AnyEvent::Loop::run;
}
ok($count==4,"Should have run something!");
ok($self->que_count==0,'que count should be empty');
  ok(scalar(keys %{$self->results})==0,'should have no results left') or diag Dumper($self->results);
  ok(!$self->stack->has_next,'stack should be empty');
}
if(1){
  my $count=0;
  my $req=HTTP::Request->new(GET=>'https://google.com');
  my @ids;
  my $code;
  $code=sub {
    my ($obj,$request,$result)=@_;
    isa_ok($obj,$class);
    isa_ok($request,'HTTP::Request');
    isa_ok($result,'HTTP::Response');
    diag sprintf 'HTTP Response code: %i %s',$result->code,$request->uri;
    ++$count;
  };
  push @ids,$self->add_cb($req,$code);
  $self->block_for_ids(@ids);
  ok($count==scalar(@ids),'should have blocked ono and run just 1 connections!');
ok($self->que_count==0,'que count should be empty');
  ok(scalar(keys %{$self->results})==0,'should have no results left') or diag Dumper($self->results);
  
  ok(!$self->stack->has_next,'stack should be empty');
}
if(1){
  my $count=0;
  my $req=HTTP::Request->new(GET=>'https://google.com');
  my $req_b=HTTP::Request->new(GET=>'https://yahoo.com');
  my $req_c=HTTP::Request->new(GET=>'https://news.com');
  my $req_d=HTTP::Request->new(GET=>'https://127.0.0.1:5888');
  my @ids;
  my $code;
  $code=sub {
    my ($obj,$request,$result)=@_;
    isa_ok($obj,$class);
    isa_ok($request,'HTTP::Request');
    isa_ok($result,'HTTP::Response');
    diag sprintf 'HTTP Response code: %i, %s',$result->code,$request->uri;
    ++$count;
  };
  push @ids,$self->add_cb($req,$code);
  push @ids,$self->add_cb($req_b,$code);
  push @ids,$self->add_cb($req_c,$code);
  push @ids,$self->add_cb($req_d,$code);
  $self->block_for_ids(@ids);
  ok($count==scalar(@ids),'should have blocked ono and run just 4 connections!');
  
  ok(scalar(keys %{$self->results})==0,'should have no results left') or diag Dumper($self->results);
  ok(!$self->stack->has_next,'stack should be empty');
}
if(1){
my $count=0;
my $chunks=0;
my $total=0;
my $body_sizes=0;
TEST_LOOP: {
  my $req=HTTP::Request->new(GET=>'https://google.com');
  my $req_b=HTTP::Request->new(GET=>'https://yahoo.com');
  my $req_c=HTTP::Request->new(GET=>'https://news.com');
  $total=3;
  my @todo;
  push @todo,HTTP::Request->new(GET=>'https://127.0.0.1:5888');
  push @todo,HTTP::Request->new(GET=>'https://127.0.0.1:5887');
  push @todo,HTTP::Request->new(GET=>'https://127.0.0.1:5886');
  push @todo,HTTP::Request->new(GET=>'https://127.0.0.1:5885');
  $total +=scalar(@todo);
  

  my $on_body=sub {
    my ($getter,$request,$headers,$body)=@_;
    ++$chunks;
    isa_ok($request,'HTTP::Request');
    isa_ok($headers,'HTTP::Headers');
    diag sprintf 'uri is %s',$request->uri;
    diag sprintf 'status code was: %i',$headers->header('Status');
    diag sprintf 'content length was: %i',length($body);
  };
  my $code;
  $code=sub {
    my ($obj,$request,$result)=@_;
    isa_ok($obj,$class);
    isa_ok($request,'HTTP::Request');
    isa_ok($result,'HTTP::Response');
    diag sprintf 'HTTP Response code: %i %s',$result->code,$request->url;
    ++$count;
    diag "We are at response $count";
    if(my $next=shift @todo) {
      $self->add_cb([$next,on_body=>$on_body],$code);
      $self->run_next;
    }
    no warnings;
    last TEST_LOOP if $count==$total;
  };
  $self->add_cb([$req,on_body=>$on_body],$code);
  $self->add_cb([$req_b,on_body=>$on_body],$code);
  $self->add_cb([$req_c,on_body=>$on_body],$code);
  $self->run_next;
  AnyEvent::Loop::run;
}
ok($chunks >0,'Should have more than 0 chunks');
ok($count==$total,"Should have run something!");
ok($self->que_count==0,'que count should be empty');
  ok(scalar(keys %{$self->results})==0,'should have no results left') or diag Dumper($self->results);
  ok(!$self->stack->has_next,'stack should be empty');
}
}
done_testing;
