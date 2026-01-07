package Test::Utils;

# just a common set of utilities for unit and integration tests, and tutorial.

use strict;
use warnings;

use Carp qw(confess);
use FindBin;
use File::Path qw(make_path);
use File::Spec;
use Log::Log4perl qw(:easy);
use Test::More;
use Try::Tiny;
use Type::Params qw(validate validate_named);
use YAML::Any qw(Dump);

use Exporter qw(import);
our @EXPORT_OK = qw(
  Dump
  init_logger $OFF $FATAL $WARN $ERROR $INFO $DEBUG $TRACE
  find_test_caller
  debug_on debug_off
  is_array is_hash is_valid_n is_valid is_not_valid is_deeply_tied
);
our %EXPORT_TAGS = (all => [ @EXPORT_OK ]);

# if you pass a logger level, it will be used with easy_init and ignore GOOGLE_RESTAPI_LOGGER.
# if you want your own logger, specify the logger config file in GOOGLE_RESTAPI_LOGGER env var
# and pass nothing to this routine. if no level and no env var set, do nothing.
# levels are: $OFF $FATAL $WARN $ERROR $INFO $DEBUG $TRACE. all these log4perl scalars
# scalars are expored above.
sub init_logger {
  my $level = shift || $ENV{GOOGLE_RESTAPI_LOG_LEVEL};
  my $logger_conf = $ENV{GOOGLE_RESTAPI_LOGGER};

  if ($logger_conf) {
    die "'$logger_conf' is not a readable file" unless -f $logger_conf;
    Log::Log4perl->init($logger_conf);
  } elsif ($level) {
    Log::Log4perl->easy_init($level);
  }

  return;
}

# this is for etc/log4perl.conf to call back to get the log file name.
sub log_file_name {
  my $logfile = shift or die "No log file passed";
  $logfile .= ".log";

  my $username = ($ENV{LOGNAME} || $ENV{USER} || getpwuid($<)) or die "No user name found";
  my $tmpdir = File::Spec->tmpdir();
  my $logdir = File::Spec->catfile($tmpdir, $username);
  make_path($logdir);

  my $logpath = File::Spec->catfile($logdir, $logfile);
  warn "File logging will be sent to $logpath\n";
  return $logpath;
}

# used for building/reading exchanges for unit testing. finds the calling
# subroutine under the testing framework to associate with the exchange. would
# normally be just the T::G::RestApi caller, but to support mock spreadsheets,
# also check Test::Unit::TestBase::startup|shutdown.
sub find_test_caller {
  my $test_base_method;
  my $test_child_method;
  for (0..30) {
    my ($package, undef, undef, $subroutine) = caller($_);
    last unless $package;
    next unless $subroutine =~ /^(Test::Google::RestApi::|Test::Unit::TestBase::startup|Test::Unit::TestBase::shutdown)/;
    if ($subroutine =~ /^Test::Unit::TestBase::/) {
      $test_base_method = $subroutine;
    } else {
      $test_child_method = $subroutine;
      last;
    }
  }
  my $test_method = $test_child_method || $test_base_method;
  confess "Unable to locate test subroutine to find exchanges" unless $test_method;

  return $test_child_method || $test_base_method;
}

# call these to temporarily toggle debug-level logger messages around particular tests so you
# can see internally what's going on within the framework.
sub debug_on  { Log::Log4perl->get_logger('')->level($DEBUG); }
sub debug_off { Log::Log4perl->get_logger('')->level($OFF); }

# test::more extensions. used to do basic tests of the response to the rest api.
sub is_array {
  my ($array, $test_name) = @_;
  $array = $array->() if ref($array) eq 'CODE';
  is ref($array), 'ARRAY', "$test_name should return an array";
}

sub is_hash {
  my ($hash, $test_name) = @_;
  $hash = $hash->() if ref($hash) eq 'CODE';
  is ref($hash), 'HASH', "$test_name should return a hash";
}

# this is a happy medium between testing for a basic type (hashref, arrayref etc) and is_deeply
# which requires fully equal hashes and arrays. we can validate basic types using the familiar
# type::params to ensure the passed blob validates correctly.
sub is_valid {
  my $test_name = '';
  $test_name = pop if !ref($_[-1]);
  $test_name .= ' passes validation' if $test_name;

  my ($values, @validation) = @_;

  my @result;
  try {
    $values = $values->() if ref($values) eq 'CODE';
    @result = validate([$values], @validation);
    pass $test_name;
  } catch {
    my $err = $_;
    fail "$test_name: $err";
  };
  return @result;
}

sub is_not_valid {
  my $test_name = '';
  $test_name = pop if !ref($_[-1]);
  $test_name .= ' does not pass validation' if $test_name;

  my ($values, @validation) = @_;

  try {
    $values = $values->() if ref($values) eq 'CODE';
    validate([$values], @validation);
    fail $test_name;
  } catch {
    pass $test_name;
  };
  return;
}

sub is_valid_n {
  my $test_name = '';
  $test_name = pop if !ref($_[-1]);
  $test_name .= ' passes validation' if $test_name;

  my ($hash, @validation) = @_;

  try {
    $hash = $hash->() if ref($hash) eq 'CODE';
    validate_named([$hash], @validation);
    pass $test_name;
  } catch {
    my $err = $_;
    fail "$test_name: $err";
  };
  return;
}

sub is_deeply_tied {
  my ($got, $expected, $title) = @_;
  my %got;
  @got{ keys %$got } = values %$got;
  return is_deeply \%got, $expected, $title;
}

1;
