use Modern::Perl;
use Log::LogMethods::Log4perlLogToString;
use Test::More qw(no_plan);
use HTTP::Response;
use HTTP::Headers;
use HTTP::Request;
use Data::Dumper;
use AnyEvent::Loop;
use Scalar::Util qw(looks_like_number);
use Carp qw(confess);
BEGIN { $SIG{__DIE__} = sub { confess @_ }; }

my $string;
our $class='HTTP::MultiGet';
my $log=LoggerToString($class,$string);
#my $log=LoggerToFh($class,*STDERR,"# $Log::LogMethods::Log4perlLogToString::DEFAULT_LAYOUT");


require_ok($class);
use_ok($class);


my $self=$class->new;
our ($ID,$REQ);
$self->on_create_request_cb(sub { ($ID,$REQ)=@_ });
$self->logger($log);
#$self->max_retry(0);
isa_ok($self,$class);


SKIP: { skip 'Run HTTP::Tests Not Set',415 unless $ENV{RUN_HTTP_TESTS};
if(1) {
  my $request=HTTP::Request->new(GET=>'http://localhost');
  my ($id)=$self->add($request);
  cmp_ok($id,'==',$ID,"on_create_request_cb testing");
  isa_ok($REQ,$self->SENDER_CLASS) or die diag "$REQ ".$self->SENDER_CLASS;
  cmp_ok($id,'==',1,'First request id should be 1');

  my $result=$self->has_request($id);
  isa_ok($result,$self->RESULT_CLASS);
  ok($result,'request should exist');
  cmp_ok($result->get_data,'eq','in_que','should show as in que');
  {
    my $result=$self->stack->has_id($id);
    isa_ok($result,$self->stack->RESULT_CLASS);

    my $request=$result->get_data;
    ok($result,'stack should have the request');
    my $headers=HTTP::Headers->new(Status=>200,Content_Type=>'text/plain');
    my $response=HTTP::Response->new(200,'Ok',$headers);
    $response->content('this was a test');
    $request->respond_with($response);

    {
      my $result=$self->block_for_ids($id);
      isa_ok($result,$self->RESULT_CLASS);
      ok($result,'Result should be true');
      is_deeply($result->get_data,{$id=>$self->new_true($response)},'validate our callback flow');
    }
  }
  cmp_ok($self->running_count,'==',0,'Running count should be 0');
  #diag $string;
}
if(1) {
  $string='';
  my $request=HTTP::Request->new(GET=>'http://localhost');
  my ($id)=$self->add($request);
  cmp_ok($id,'==',2,'First request id should be 1');

  my $result=$self->has_request($id);
  isa_ok($result,$self->RESULT_CLASS);
  ok($result,'request should exist');
  cmp_ok($result->get_data,'eq','in_que','should show as in que');
  {
    my $result=$self->stack->has_id($id);
    isa_ok($result,$self->stack->RESULT_CLASS);

    {
      my $result=$self->block_for_ids($id);
      isa_ok($result,$self->RESULT_CLASS);
      ok($result,'Result should be true');
    }
  }
  cmp_ok($self->running_count,'==',0,'Running count should be 0');
  #diag $string;
}
if(1){
  
  my @ids=$self->add(map { HTTP::Request->new(GET=>'http://localhost') } 1 .. 12 );
  foreach my $id (@ids) {
    $string='';

    my $result=$self->has_request($id);
    isa_ok($result,$self->RESULT_CLASS);
    ok($result,'request should exist');
    {
      my $result=$self->stack->has_id($id);
      isa_ok($result,$self->stack->RESULT_CLASS);

      {
        my $result=$self->block_for_ids($id);
        isa_ok($result,$self->RESULT_CLASS);
        ok($result,'Result should be true');
      }
    }
    #diag $string;
  }
}

if(1){
  my $response=HTTP::Response->new(500,"Internal Server Error");
  $self->on_create_request_cb(sub {
    my ($id,$req)=@_;
    $req->respond_with($response);
  }
  );
  my @responses=$self->run_requests(HTTP::Request->new(GET=>'http://localhost:6503'));
  isa_ok($responses[0],'HTTP::Response');
  cmp_ok($self->running_count,'==',0,'Running count should be 0');
  ok(!$self->has_running_or_pending,'Noting Should be running or pending!');

}
if(1) {
  
  $self->on_create_request_cb(sub {});
  foreach my $test_id ( 1 .. 3 ) {
    $self->max_que_count($test_id);
    $self->timeout($test_id * 2);
    my @requests=(map { HTTP::Request->new(GET=>'http://localhost:6503') } (1 .. $test_id * 5));
    my @responses=$self->run_requests(@requests);


    my $id=0;
    my $total=scalar(@requests);
    foreach my $response (@responses) {
      ++$id;
      isa_ok($response,'HTTP::Response');
      my $code=$response->code ;
      ok(looks_like_number($code),"Stress test: $test_id max_que_count: ".$self->max_que_count." timeout: ".$self->timeout." Response test $id/$total should be a mumber");
      ok(length($response->status_line) >0,"Stress test: $test_id Should have some value in the status line for code: $code");
      diag $response->status_line;
    }
    cmp_ok($self->running_count,'==',0,'Running count should be 0');
  }
  ok(!$self->has_running_or_pending,'Noting Should be running or pending!');
}

# Negative testing, these results should no longer exist
{
  my @ids=(1 .. 100);
  my @results=$self->get_results(@ids);
  for(my $key=0;$key < scalar(@ids);++$key) {
    my $id=$ids[$key];
    my $response=$results[$key];
    isa_ok($response,'HTTP::Response');
    cmp_ok($response->code,'==',500,"Testing fake Result: $id");
  }
}

{
    $self->clean_results;
    $self->on_create_request_cb(
      sub {
        my ($id,$req)=@_;
        $req->respond_with(HTTP::Response->new('200','OK',HTTP::Headers->new(Status=>200),"this is a test of id: [$id]"));
      }
    );
    my @requests=(
      (map { HTTP::Request->new(GET=>'http://localhost:6503') } (1 .. 2))
      ,(map { HTTP::Request->new(PUT=>'http://localhost') } (1 .. 5))
    );
    $self->timeout(10);
    $self->max_que_count(10);
    my @ids=$self->add(@requests);
    {
      my @ids=@ids[0,1];
      my @results=$self->block_for_results_by_id(@ids);
      foreach my $response (@results) {
        my $id=shift @ids;
        isa_ok($response,'HTTP::Response');
	cmp_ok($response->code,'==',200,"Testing: id $id Should get code 200");
      }
    }
    {
      my ($bad_a,$bad_b,@results)=$self->get_results(@ids);
      my ($id_a,$id_b,@ids)=@ids;


      foreach my $response (@results) {
        my $id=shift @ids;
        isa_ok($response,'HTTP::Response');
	cmp_ok($response->code,'==',200,"Testing id: $id Should get code 200");
      }

      {
        my @ids=($id_a,$id_b);
        foreach my $response ($bad_a,$bad_b) {
          isa_ok($response,'HTTP::Response');
          my $id=shift @ids;
	  cmp_ok($response->code,'==',500,"Negative Testing id: $id Should get code 500");
        }
      }
    }
   cmp_ok(scalar(keys %{$self->results}),'==',0,'Should have 0 results left');
}
{
  #$self->max_retry(5);
  $self->on_create_request_cb(sub {});
  my @ids=$self->add(map { HTTP::Request->new(GET=>'http://localhost:'.(32768 + $_)) } 1 .. 10 );
  my @results=$self->block_for_results_by_id(@ids);
  foreach my $result (@results) {
   isa_ok($result,'HTTP::Response');
  }

}

$self->clean_results;
ok('Clean results shoudld not cause an error');
cmp_ok(scalar(keys %{$self->results}),'==',0,'Should have no local results!');


$self=test->new();
OUR_LOOP: {
  my @requests=(map { HTTP::Request->new(GET=>'http://localhost:6503') } (1 .. 2));
  $self->add(@requests);
  isa_ok($self,'test');
  $self->run_next;
  AnyEvent::Loop::run;
}
{
  my $results=$self->results;
  my $total=0;

  while(my ($id,$result)=each %{$results}) {
    ++$total;
    ok($result,'Result should be true');
    isa_ok($result,'Data::Result');
    isa_ok($result->get_data,'HTTP::Response');
  }
}
{
  package test;
  use Modern::Perl;
  use Moo;
  BEGIN { extends 'HTTP::MultiGet'; }
  sub que_function {
    my ($self,@args)=@_;
    my $code=$self->SUPER::que_function(@args);

    return sub { 
      $code->(@_);
      $self->log_always("our que count is: ".$self->que_count);
      no warnings;
      last OUR_LOOP if $self->que_count==0;
    };
  }
}
}
done_testing;
