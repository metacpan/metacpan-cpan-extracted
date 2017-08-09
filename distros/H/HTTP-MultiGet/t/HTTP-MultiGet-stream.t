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

SKIP: { 
  skip 'env variable STREAM_URL not set',415 unless $ENV{STREAM_URL};
  my $count=0;
  my $req=HTTP::Request->new(GET=>$ENV{STREAM_URL});
  my $on_body=sub {
    my ($obj,$request,$headers,$body)=@_;
    isa_ok($request,'HTTP::Request');
    isa_ok($headers,'HTTP::Headers');
    ++$count;
  };
  my ($result)=$self->run_requests([$req,on_body=>$on_body]);
  ok($count!=0,"Validating we got a callback count: $count");
  ok($result->code==200,'Result code should be 200');
  ok(!$result->decoded_content,'Result object should be empty');
  
}
