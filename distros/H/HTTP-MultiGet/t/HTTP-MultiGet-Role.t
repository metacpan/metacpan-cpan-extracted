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
my $module='HTTP::MultiGet::Role';
require_ok($module);
my $class='SomeTestClass';
my $log=LoggerToString($class,$string);

my $self=$class->new;

isa_ok($self,$class);

SKIP: {
  skip '$ENV{RUN_HTTP_TESTS}!=1', 25 unless $ENV{RUN_HTTP_TESTS};

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
    isa_ok($result,'Data::Result');
    ok($result,'Should fetch google.com without issues');
    cmp_ok($pass_count,'==',100,'Should have a pass count of 100');
    cmp_ok($fail_count,'==',100,'Should have a fail count of 100');
    cmp_ok($rec_pass,'==',100,'Should have a recursive pass count of 100');
    cmp_ok($rec_fail,'==',100,'Should have a recursive fail count of 100');
    cmp_ok($sp_count,'==',3,'Sleep recursive pass count: 3');
  }

  {
    
    my $result=$self->fail;
    isa_ok($result,'Data::Result') or diag Dumper($result,$self->agent->results);
    ok(!$result,'should have a failed result');
  }
  {
    
    my $result=$self->pass;
    isa_ok($result,'Data::Result') or diag Dumper($result,$self->agent->results);
    ok($result,'should have a good result');
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

  my $tv;
  TEST_LOOP: {
    $tv=AnyEvent->timer(after=>4,cb=>sub { no warnings;last TEST_LOOP});
    $self->agent->run_next;
    AnyEvent::Loop::run;
    undef $tv;
  }
  cmp_ok($count,'==',1,'should have used 1 call back');
  cmp_ok($count_pass,'==',5,'should have used all 5 pass call backs');
  cmp_ok($count_fail,'==',5,'should have used all 5 fail call backs');
}

{
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

  sub que_fail {
    my ($self,$cb)=@_;
    return $self->queue_result($cb,$self->new_false('I am a failure!'));
  }

  sub que_pass {
    my ($self,$cb)=@_;
    return $self->queue_result($cb,$self->new_true({}));
  }
}
