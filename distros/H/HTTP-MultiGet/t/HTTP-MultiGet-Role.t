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

my $self=$class->new;

isa_ok($self,$class);


  {
    
    my $result=$self->fail;
    isa_ok($result,'Data::Result') or die Dumper($result);
    ok(!$result,'should have a failed result');
  }
  {
    
    my $result=$self->pass;
    isa_ok($result,'Data::Result') or die Dumper($result,$self->agent->results);
    ok($result,'should have a good result');
  }
  {
    my $id=$self->queue_result(undef,Data::Result->new_true({}));
    my $result=$self->block_on_ids($id);
    ok($result,'Should get our fake result');
  }
  our $STAGE=0;
SKIP: {
  skip '$ENV{RUN_HTTP_TESTS}!=1', 40 unless $ENV{RUN_HTTP_TESTS};


  {
    my $pass_count=0;
    my $fail_count=0;

    for(0 .. 99) {
      $self->que_pass(sub { ++$pass_count });
      $self->que_fail(sub { ++$fail_count });
    }

    my $rec_pass=0;
    my $rec_fail=0;

    my ($rec_ps,$rec_fs);

    $rec_ps=sub { $self->que_pass($rec_ps) if ++$rec_pass <100 };
    $rec_fs=sub { $self->que_fail($rec_fs) if ++$rec_fail <100 };
    $self->que_pass($rec_ps);
    $self->que_fail($rec_fs);

    my $sp_count=0;
    my $sp_rec;
    $sp_rec=sub {
      sleep 1;
      ++$sp_count;
      $self->que_pass($sp_rec) if $sp_count <3;
    };
    $self->que_pass($sp_rec);
    my $result=$self->google;
    isa_ok($result,'Data::Result') or die;
    ok($result,'Should fetch google.com without issues');
    cmp_ok($pass_count,'==',100,'Should have a pass count of 100');
    cmp_ok($fail_count,'==',100,'Should have a fail count of 100');
    cmp_ok($rec_pass,'==',100,'Should have a recursive pass count of 100');
    cmp_ok($rec_fail,'==',100,'Should have a recursive fail count of 100');
    cmp_ok($sp_count,'==',3,'Sleep recursive pass count: 3');
  }

  # 6

  my $count_pass=0;
  my $count_fail=0;
  my $count=0;
  my ($pass_sub,$fail_sub);
  $pass_sub=sub {
    my ($self,$id,$result)=@_;
    ok($result,'Should get called on pass');
    $self->que_pass($pass_sub) if ++$count_pass <5;
  };
  $fail_sub=sub {
    my ($self,$id,$result)=@_;
    ok(!$result,'Should get called on fail');
    $self->que_fail($fail_sub) if ++$count_fail <5;
  };
  $self->que_pass($pass_sub);
  $self->que_fail($fail_sub);

  $self->que_google(sub { 
    my ($self,$id,$result)=@_;
    ok($result,'Should get called on google request');
    ++$count;
  });


  TEST_LOOP: {
    my $cv=AnyEvent->condvar;
    my $tv=AnyEvent->timer(after=>4,cb=>sub { $cv->send});
    $self->agent->run_next;
    $cv->recv;
  }

  cmp_ok($count,'==',1,'should have used 1 call back');
  cmp_ok($count_pass,'==',5,'should have used all 5 pass call backs');
  cmp_ok($count_fail,'==',5,'should have used all 5 fail call backs');
  ok($self->google,'blocking fetch google.com test');
  $STAGE=4;
  isa_ok($self->subfetch,'Data::Result');
  cmp_ok($STAGE,'==',0,'Should have 0 remaining requests');
  TEST_LOOP: {
    $STAGE=4;
    my $self=$class->new;
    my $cv=AnyEvent->condvar;
    my $tv=AnyEvent->timer(after=>4,cb=>sub { $cv->send});
    $self->que_google(sub { ok(1,'run google lookup')});;
    $self->que_fail(sub { diag Dumper $_[0]->agent->results; ok(1,'run fail')});
    $self->que_pass(sub { ok(1,'run pass')});
    $self->agent->run_next;
    $cv->recv;
    diag Dumper([sort keys %{$self->agent->results}]);
  }
  {
    $STAGE=4;
    my $self=$class->new;
    my $cv=AnyEvent->condvar;
    my $tv=AnyEvent->timer(after=>4,cb=>sub { $cv->send});
    ok($self->que_subfetch(sub { ok(1,'Sub fetch should have run!')}),'fire ouf our subfetch in non blocking mode');
    $self->agent->run_next;
    $cv->recv;
    cmp_ok($STAGE,'==',0,'Should have 0 remaining requests');
    diag Dumper([sort keys %{$self->agent->results}]);
  }
}

{
  my $sub=$self->can('pass');
  ok($sub,'Should return a code refrence');
  my $result=$sub->($self);
  isa_ok($result,'Data::Result');
  ok($result,'result should be true');
  ok(!$self->can('bad_function_should_not_exist'),'Should fail to return a function that does not exist');

  $sub=$self->can('que_google');
  cmp_ok($sub,'eq',\&SomeTestClass::que_google,'Validate $self->SUPER::can($method)');

}

{
  my $test="this is a test";
  ok($self->json->get_allow_nonref,'non ref mode should be enabled');
  my $in=qq{"$test"};
  cmp_ok($self->json->decode($in),'eq',$test,'should now decode non refs');
}

for my $code (200 .. 299 ){
  {
    my $response=HTTP::Response->new($code,'ok',[],q{{"test": "testing"}});
    my $result=$self->parse_response(undef,$response);
    ok($result,'Should get true as a response, code: '.$code);
    is_deeply($result->get_data,{test=>"testing"},'parse a json hash with a code $code');
  }
  {
    my $response=HTTP::Response->new($code,'ok',[],q{["test", "testing"]});
    my $result=$self->parse_response(undef,$response);
    ok($result,'Should get true as a response, code: '.$code);
    is_deeply($result->get_data,[test=>"testing"],'parse a json array with a code $code');
  }
  {
    my $response=HTTP::Response->new($code,'ok',[],q{"test"});
    my $result=$self->parse_response(undef,$response);
    ok($result,'Should get true as a response, code: '.$code);
    cmp_ok($result->get_data,'eq','test','parse a json string with a code $code');
  }
}
for my $code (199,400,401,300,500,501,595) {
    my $response=HTTP::Response->new($code,'fail',[],q{{"test": "testing"}});
    my $result=$self->parse_response(undef,$response);
    ok(!$result,'Should fail a code: '.$code);
}

BEGIN {
  package 
    SomeTestClass;
  use Modern::Perl;
  use Moo;
  use Data::Dumper;
  BEGIN {
  with 'HTTP::MultiGet::Role';
  }
  sub que_google {
    my ($self,$cb)=@_;
    my $req=new HTTP::Request(GET=>'https://google.com');
    return $self->queue_request($req,$cb);
  }
  sub que_subfetch {
    my ($self,$cb)=@_;
    my $req=new HTTP::Request(GET=>'https://google.com');
    my $code=sub {
     my ($self,$id,$result)=@_;
     ::diag("Main Request ran");
     ::ok(1,"Main google fetch ran");
     my $req=new HTTP::Request(GET=>'https://google.com');
     $self->add_ids_for_blocking($self->queue_request($req,sub {
       main::diag "request 1 ran: $id";
       main::ok($result,'Que sending multiple requests');
       $STAGE--;
       my $count=0;
       for my $req_id (1 .. 3) {
         my $req=new HTTP::Request(GET=>'https://google.com');
         ++$count;
	 --$STAGE;
         $self->add_ids_for_blocking($self->queue_request($req,sub { 
	   --$count;
	   (undef,undef,$result)=@_;
	   main::ok($result,'Sub request [$req_id]  ok');
	   return unless $count==0; 

	   ::diag("using ID, $id, current count is [$count]\n");
           $cb->($self,$id,$result,$req,undef) ;
	   ::diag('current list of result map keys: ', join ', ',keys %{$self->result_map});
	 }));
       }
     }));
    };
    my $id=$self->queue_request($req,$code);
    ::diag("Queing $id");
    return $id;
  }

  sub que_fail {
    my ($self,$cb)=@_;
    return $self->queue_result( sub {$cb->(@_) },$self->new_false('I am a failure!'));
  }

  sub que_pass {
    my ($self,$cb)=@_;
    return $self->queue_result($cb,$self->new_true({}));
  }
}

