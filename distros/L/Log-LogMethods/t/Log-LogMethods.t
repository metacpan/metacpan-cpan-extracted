use Modern::Perl;
no warnings 'redefine';
use Test::More qw(no_plan);
use IO::Scalar;
use Data::Dumper;
use Data::Result;
use Log::Log4perl;
use Log::Log4perl::Layout;
use Log::Log4perl::Level;
use Log::Dispatch;
use Log::LogMethods::Log4perlLogToString;
require_ok('Log::LogMethods');
use_ok('Log::LogMethods');
#Log::Log4perl->wrapper_register(__PACKAGE__);
our @DATA;
our $LINE=__LINE__;
our $DEBUG=0;

no warnings 'redefine';
foreach my $method (qw(tv_interval gettimeofday is_plain_hashref is_blessed_hashref svref_2object looks_like_number freeze thaw)) {
  ok(!Log::LogMethods->can($method),"Log::LogMethods should not expose method: $method");
}

foreach my $class (qw(test_base test_parent test_header )) {

  my $self=$class->new();
  ok(!$self->level,'should return false when we try to call a bad logger object for class: '.$class);
}

foreach my $class (qw(test_base test_parent test_header )) {

  my $string='';
  my $log=LoggerToString($class,$string,'%H %P %d %p %f %k %S %h %s %b %j %B%n');
  my $self=$class->new(logger=>$log);

  foreach my $level (qw(always warn info debug error)) {
    $string='';
    my $method="res_$level";
    $log->level($Log::LogMethods::LEVEL_MAP{uc($level)});
    $self->$method(new_true Data::Result());
    my $header=' ';
    $header=' '.$class->log_header.' ' if $class->can('log_header');
    my $re=qr{${class}::$method${header}\s*Starting\s*\d.*Finished \d elapsed}s;
    like($string,$re,"Validate Log4perl $class->$method(new_true Data::Result()) logging for BENCHMARK_".uc($level)) or die diag $string if $DEBUG;

    $string='';
    my @args=(new_false Data::Result("error message"));
    $self->$method(@args);
    diag $string if $DEBUG;
    is_deeply(\@DATA,\@args,"Make sure Input putput args match for $class->$method(\@args)");
    if($level ne 'always') {
      $re=qr{${class}::$method${header}\s*Starting\s*\d.*$args[0].*Finished \d elapsed}s;
    } else {
      $re=qr{${class}::$method${header}\s*Starting\s*\d.*Finished \d elapsed}s;
    }
    like($string,$re,"Validate Log4perl logging for RESULT_ERROR $class->$method(new_false Data::Result()) BENCHMARK_".uc($level)) or die diag $string,Dumper(\%{Log::LogMethods::LEVEL_MAP});

    $string='';
    $method="log_$level";
    $self->call_method($method,'This is a test!!!');
    $re=qr{ $LINE ${class}::call_method${header}\s*This is a test!!!}s;
    like($string,$re,"Validating $class->$method($class->$method('msg')  when using log4perl") or die diag $string if $DEBUG;
    $string='';
    $self->$method('More testing');$LINE=__LINE__;
    $re=qr{ $LINE main::${header}\s*More testing}s;
    like($string,$re,"Validating $class->$method(msg) when using log4perl") or die diag $string if $DEBUG;
  }

}

sub log_sample {
  my ($log)=@_;
  $log->info("This is a test");
}
{
  my $string;
  my $log=LoggerToString(__PACKAGE__,$string,'%H %P %d %p %f %k %S %h %s %b %j %B%n');
  $log->level($Log::LogMethods::LEVEL_MAP{INFO});
  my $l=new test_header(logger=>$log);
  log_sample($l);
  like($string,qr{This is a test},'validate stand alone loging is not broken');
  $string='';
  $l->info("This is a test");
  like($string,qr{This is a test},'validate stand alone loging is not broken');
  $string='';
  no_guts->call_method($l,'info','yet another scurvy driven test!');
  like($string,qr{yet another scurvy driven test},'validate stand alone loging is not broken');
  $string='';
  
  eval { $l->log_die("Bang you are dead!") };
  ok($@,'Should have $@');
  like($string,qr{Bang you are dead!},'validate stand alone loging is not broken');

}


{
  diag Dumper(\%{Log::LogMethods::LEVEL_MAP}) if $DEBUG;
}
{
  package no_guts;

  sub call_method {
    my ($self,$log,$method,$msg)=@_;
    $log->$method($msg);
  }
}
{
  package test_header;

  sub new {
    my ($class,%args)=@_;
    bless {%args},$class;
  }
  use base qw(Log::LogMethods);

  use constant log_header =>'AUTO LOG HEADER TEST';
  use Data::Dumper;

  sub test_always : BENCHMARK_ALWAYS { shift;@DATA=@_; wantarray ? (1,2) : 31  }
  sub test_error : BENCHMARK_ERROR { shift;@DATA=@_; wantarray ? (1,2) : 31  }
  sub test_warn : BENCHMARK_WARN { shift;@DATA=@_; wantarray ? (1,2) : 31  }
  sub test_info : BENCHMARK_INFO { shift;@DATA=@_; wantarray ? (1,2) : 31  }
  sub test_debug : BENCHMARK_DEBUG { shift;@DATA=@_; wantarray ? (1,2) : 31  }

  sub call_method { my ($self,$method,$msg)=@_; $self->$method($msg);$LINE=__LINE__ }

  sub res_always : BENCHMARK_ALWAYS { shift;@DATA=@_; wantarray ? (@_) : $_[0]  }
  sub res_error : BENCHMARK_ERROR { shift;@DATA=@_; wantarray ? (@_) : $_[0]  }
  sub res_warn : BENCHMARK_WARN { shift;@DATA=@_; wantarray ? (@_) : $_[0]  }
  sub res_info : BENCHMARK_INFO { shift;@DATA=@_; wantarray ? (@_) : $_[0]  }
  sub res_debug : BENCHMARK_DEBUG { shift;@DATA=@_; wantarray ? (@_) : $_[0]  }

  sub result_always : RESULT_ALWAYS { shift;@DATA=@_; wantarray ? (@_) : $_[0]  }
  sub result_error : RESULT_ERROR { shift;@DATA=@_; wantarray ? (@_) : $_[0]  }
  sub result_warn : RESULT_WARN { shift;@DATA=@_; wantarray ? (@_) : $_[0]  }
  sub result_info : RESULT_INFO { shift;@DATA=@_; wantarray ? (@_) : $_[0]  }
  sub result_debug : RESULT_DEBUG { shift;@DATA=@_; wantarray ? (@_) : $_[0]  }
}
{
  package test_base;

  sub new {
    my ($class,%args)=@_;
    bless {%args},$class;
  }
  use base qw(Log::LogMethods);

  sub call_method { my ($self,$method,$msg)=@_; $self->$method($msg);$LINE=__LINE__ }
  sub test_always : BENCHMARK_ALWAYS { shift;@DATA=@_; wantarray ? (1,2) : 31  }
  sub test_error : BENCHMARK_ERROR { shift;@DATA=@_; wantarray ? (1,2) : 31  }
  sub test_warn : BENCHMARK_WARN { shift;@DATA=@_; wantarray ? (1,2) : 31  }
  sub test_info : BENCHMARK_INFO { shift;@DATA=@_; wantarray ? (1,2) : 31  }
  sub test_debug : BENCHMARK_DEBUG { shift;@DATA=@_; wantarray ? (1,2) : 31  }

  sub res_always : BENCHMARK_ALWAYS { shift;@DATA=@_; wantarray ? (@_) : $_[0]  }
  sub res_error : BENCHMARK_ERROR { shift;@DATA=@_; wantarray ? (@_) : $_[0]  }
  sub res_warn : BENCHMARK_WARN { shift;@DATA=@_; wantarray ? (@_) : $_[0]  }
  sub res_info : BENCHMARK_INFO { shift;@DATA=@_; wantarray ? (@_) : $_[0]  }
  sub res_debug : BENCHMARK_DEBUG { shift;@DATA=@_; wantarray ? (@_) : $_[0]  }

  sub result_always : RESULT_ALWAYS { shift;@DATA=@_; wantarray ? (@_) : $_[0]  }
  sub result_error : RESULT_ERROR { shift;@DATA=@_; wantarray ? (@_) : $_[0]  }
  sub result_warn : RESULT_WARN { shift;@DATA=@_; wantarray ? (@_) : $_[0]  }
  sub result_info : RESULT_INFO { shift;@DATA=@_; wantarray ? (@_) : $_[0]  }
  sub result_debug : RESULT_DEBUG { shift;@DATA=@_; wantarray ? (@_) : $_[0]  }
}
{
  package test_parent;

  sub new {
    my ($class,%args)=@_;
    bless {%args},$class;
  }
  use base qw(Log::LogMethods);

  sub call_method { my ($self,$method,$msg)=@_; $self->$method($msg);$LINE=__LINE__ }
  sub test_always : BENCHMARK_ALWAYS { shift;@DATA=@_; wantarray ? (1,2) : 31  }
  sub test_error : BENCHMARK_ERROR { shift;@DATA=@_; wantarray ? (1,2) : 31  }
  sub test_warn : BENCHMARK_WARN { shift;@DATA=@_; wantarray ? (1,2) : 31  }
  sub test_info : BENCHMARK_INFO { shift;@DATA=@_; wantarray ? (1,2) : 31  }
  sub test_debug : BENCHMARK_DEBUG { shift;@DATA=@_; wantarray ? (1,2) : 31  }

  sub res_always : BENCHMARK_ALWAYS { shift;@DATA=@_; wantarray ? (@_) : $_[0]  }
  sub res_error : BENCHMARK_ERROR { shift;@DATA=@_; wantarray ? (@_) : $_[0]  }
  sub res_warn : BENCHMARK_WARN { shift;@DATA=@_; wantarray ? (@_) : $_[0]  }
  sub res_info : BENCHMARK_INFO { shift;@DATA=@_; wantarray ? (@_) : $_[0]  }
  sub res_debug : BENCHMARK_DEBUG { shift;@DATA=@_; wantarray ? (@_) : $_[0]  }


  sub result_always : RESULT_ALWAYS { shift;@DATA=@_; wantarray ? (@_) : $_[0]  }
  sub result_error : RESULT_ERROR { shift;@DATA=@_; wantarray ? (@_) : $_[0]  }
  sub result_warn : RESULT_WARN { shift;@DATA=@_; wantarray ? (@_) : $_[0]  }
  sub result_info : RESULT_INFO { shift;@DATA=@_; wantarray ? (@_) : $_[0]  }
  sub result_debug : RESULT_DEBUG { shift;@DATA=@_; wantarray ? (@_) : $_[0]  }
}
{
  package test_moo;

  use Moo;
  BEGIN {no warnings 'redefine';with 'Log::LogMethods' };
  sub call_method { my ($self,$method,$msg)=@_; $self->$method($msg);$LINE=__LINE__ }
  sub test_always : BENCHMARK_ALWAYS { shift;@DATA=@_; wantarray ? (1,2) : 31  }
  sub test_error : BENCHMARK_ERROR { shift;@DATA=@_; wantarray ? (1,2) : 31  }
  sub test_warn : BENCHMARK_WARN { shift;@DATA=@_; wantarray ? (1,2) : 31  }
  sub test_info : BENCHMARK_INFO { shift;@DATA=@_; wantarray ? (1,2) : 31  }
  sub test_debug : BENCHMARK_DEBUG { shift;@DATA=@_; wantarray ? (1,2) : 31  }

  sub res_always : BENCHMARK_ALWAYS { shift;@DATA=@_; wantarray ? (@_) : $_[0]  }
  sub res_error : BENCHMARK_ERROR { shift;@DATA=@_; wantarray ? (@_) : $_[0]  }
  sub res_warn : BENCHMARK_WARN { shift;@DATA=@_; wantarray ? (@_) : $_[0]  }
  sub res_info : BENCHMARK_INFO { shift;@DATA=@_; wantarray ? (@_) : $_[0]  }
  sub res_debug : BENCHMARK_DEBUG { shift;@DATA=@_; wantarray ? (@_) : $_[0]  }

  sub result_always : RESULT_ALWAYS { shift;@DATA=@_; wantarray ? (@_) : $_[0]  }
  sub result_error : RESULT_ERROR { shift;@DATA=@_; wantarray ? (@_) : $_[0]  }
  sub result_warn : RESULT_WARN { shift;@DATA=@_; wantarray ? (@_) : $_[0]  }
  sub result_info : RESULT_INFO { shift;@DATA=@_; wantarray ? (@_) : $_[0]  }
  sub result_debug : RESULT_DEBUG { shift;@DATA=@_; wantarray ? (@_) : $_[0]  }
}
{
  package src_test_parent;
  use Modern::Perl;
  use constant log_header=>'AUTO LOG HEADER TEST';
  use base qw(test_parent);
  1;
}

## UNIT TESTING STOPS HERE!
done_testing;

## END OF THE SCRIPT
