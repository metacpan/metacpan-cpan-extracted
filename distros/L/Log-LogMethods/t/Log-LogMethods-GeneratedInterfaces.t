use Modern::Perl;
use Test::More;
use Log::LogMethods::Log4perlLogToString;
use Data::Dumper;
use Carp qw(confess);
BEGIN { $SIG{__DIE__} = sub { confess @_ }; }

my $string='';
my $class='Log::LogMethods';
my $log=LoggerToString($class,$string,"$Log::LogMethods::Log4perlLogToString::DEFAULT_LAYOUT");
#my $log=LoggerToFh($class,*STDERR,"# $Log::LogMethods::Log4perlLogToString::DEFAULT_LAYOUT");
use_ok($class);
require_ok($class);

my $self=test->new(logger=>$log);
diag $string;

isa_ok($self,'test');
my @methods=map { 'is_'.lc($_ eq 'WARN' ? 'warning' : $_) } keys %Log::LogMethods::LEVEL_MAP;
can_ok($class,@methods) or die diag Dumper(\%Log::LogMethods::,\@methods);

my %reverse=reverse %Log::LogMethods::LEVEL_MAP;

foreach my $method (@methods) {
  my $result=$self->$method;

  ok(($method=~ /off/ ? $result : !$result),"testing $class->$method with no logger") or diag "State was: $result ";
}

$log=LoggerToString('test',$string,"$Log::LogMethods::Log4perlLogToString::DEFAULT_LAYOUT");
$self->logger($log);

diag $string;
{
  $self->level($Log::LogMethods::LEVEL_MAP{INFO});
  $self->log_info("this another test");
  diag $string;
}
#while(my ($name,$level)=each %Log::LogMethods::LEVEL_MAP) {
foreach my $name (sort keys %Log::LogMethods::LEVEL_MAP) {
  my $level=$Log::LogMethods::LEVEL_MAP{$name};
  $string='';
  ok($self->level($level),"validating, with logger we can log at level $reverse{$level}");
  cmp_ok($level,'==',$self->level,"Validate that our logging level was set to $reverse{$level}");
  my $method=lc($name eq 'WARN' ? 'warning' : $name);
  diag "testing test->$method('test message for level: $name')";
  $self->$method("test message for level: $name");my $line=__LINE__;

  # Log4perl bug, ## DEBUG level does not log anything.
  SKIP: {
    skip "log4perl default DEBUG log level does not log anything",$name eq 'DEFAULT_DEBUG';

    like($string,qr{$name $line .*test message for level: $name},"Validate line numbers and message formatting");
  }
  diag $string;

}

{
  $string='';
  $self->level($Log::LogMethods::LEVEL_MAP{INFO});
  {
    $string='';
    $self->test('log_info',"this is a test");
    my $re=qr{INFO \d+ test::test};
    like($string,$re,'Make sure we log the correct function and line');
    diag $string;
  }
  {
    $string='';
    $self->test('info',"this is a test");
    my $re=qr{INFO \d+ test::test};
    like($string,$re,'Make sure we log the correct function and line');
    diag $string;
  }
}

{
  package test;
  use Modern::Perl;
  use Moo;
  BEGIN { with 'Log::LogMethods'; }
  sub test {
   my ($self,$method,$msg)=@_;
     $self->$method($msg);
  }
}


done_testing;
