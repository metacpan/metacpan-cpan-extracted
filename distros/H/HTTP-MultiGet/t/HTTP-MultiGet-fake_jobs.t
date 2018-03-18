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


my $ran=0;
for my $count (1 .. 10) {
  $self->add_result(sub {
    $self->add_result(sub { cmp_ok(++$ran,'<=',10,"Current spawn $ran ".'should never go beyond 10 spans');
      $self->add_result(sub { cmp_ok(++$ran,'<=',10,"Current spawn $ran ".'should never go beyond 10 spans') }) if $ran<10;
    }) if $ran <10;
   $self->run_next; 
  });
}

$self->run_next;
cmp_ok($ran,'==',10,'Should have run 10 and only 10 jobs');

