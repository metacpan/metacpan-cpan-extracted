package Log::LogMethods;

use Modern::Perl;
use Time::HiRes qw(tv_interval gettimeofday);
use Ref::Util qw(is_plain_hashref is_blessed_hashref);
use Scalar::Util qw(blessed);
use B qw(svref_2object);
use Scalar::Util qw(looks_like_number);
no warnings 'redefine';
use Log::Log4perl;
use Log::Log4perl::Level;
Log::Log4perl->wrapper_register(__PACKAGE__);
use Moo::Role;

use Carp qw(croak);
use namespace::clean;

our $VERSION='1.009';
our $SKIP_TRIGGER=0;

# used as a place holder for extended format data
our $CURRENT_CB;
BEGIN { 

  # disable logging
  #local $SIG{__WARN__}=sub { };

  # always should be before off
  Log::Log4perl::Logger::create_custom_level(qw( ALWAYS OFF)); 
}

sub LOOK_BACK_DEPTH { 3; }

our %LEVEL_MAP=(
  OFF=>$OFF,
  ALWAYS=>$ALWAYS,
  FATAL=>$FATAL,
  ERROR=>$ERROR,
  WARN=>$WARN,
  INFO=>$INFO,
  DEBUG=>$DEBUG,
  TRACE=>$TRACE,
);

=pod

=head1 NAME

Log::LogMethods - Writes your logging code for you!

=head1 SYNOPSIS

  package test_moo;

  use Moo;
  BEGIN { with qw(Log::LogMethods) }
  sub test_always : BENCHMARK_ALWAYS { ...  }

  my $logger=Log::Log4perl->get_logger(__PACKAGE__);
  my $class=new test_moo(logger=>$logger);

=cut

=head1 Log4Perl Sugested PatternLayout

To get everything you were expecting from classes that extend this one, use the following PatternLayout:

  %H %P %d %p %f %k %S [%h] %s %b %j %B%n

The above format will produce logs like this:

  d00nappu0019 108201 2017/03/13 18:36:45 INFO t/Log-LogMethods.t 292 test_header::res_info [HEADER TEST] Starting 1
  d00nappu0019 108201 2017/03/13 18:36:45 ERROR t/Log-LogMethods.t 292 test_header::res_info [HEADER TEST] error message 1 
  d00nappu0019 108201 2017/03/13 18:36:45 INFO t/Log-LogMethods.t 292 test_header::res_info [HEADER TEST] Finished 1 elapsed 0.000362

=head2 Log4Perl Custom PatternLayouts

Since log4perl can get pertty confused with what the (package::method and line) number should be from Log::LogMethods, the following Custom PatternLayout have been added:

  +------------------------------------------------------+
  | Layout | Replaces | Description                      |
  +--------+----------+----------------------------------+
  | %f     |   %F     | File the alert came from         |
  | %s     |   %m     | actual Message                   |
  | %k     |   %L     | Line Number ( if any )           |
  | %S     |          | fully qualified package::method  |
  | %v     |   %C     | package                          |
  +--------+----------+----------------------------------+

Special case PatternLayouts 

  +--------+----------------------------------------+
  | %h     | Log Header value ( if any )            |
  | %b     | Benchmark recursion_level              |
  | %B     | Benchmaked time in microseconds        |
  | %j     | set to "elapsed" for benchmark methods |
  +--------+----------------------------------------+

=cut

our %FORMAT_MAP=(
  qw(
    f filename
    s msg
    k line
    h header
    S sub
    v package

    b recursion_level
    B elapsed
    j kw_elapsed
  )
);

while(my ($format,$key)=each %FORMAT_MAP) {
  Log::Log4perl::Layout::PatternLayout::add_global_cspec($format,sub {
    my ($layout, $msg, $category, $priority, $caller_level)=@_;

    my $hash=$CURRENT_CB;

    # make us a real drop in replacement!
    unless(is_plain_hashref $hash) {
      $hash=__PACKAGE__->strack_trace_to_level( $caller_level);
      while($hash->{package} eq 'Log::Log4perl::Logger') {
        ++$caller_level;
        $hash=__PACKAGE__->strack_trace_to_level( $caller_level);
	if($hash->{sub}=~ /^Log::Log4perl::Logger/s) {
	  $hash->{sub}=__PACKAGE__->strack_trace_to_level(1+ $caller_level)->{sub};
	}
      }
      $hash->{msg}=$msg;
    }
    exists  $hash->{$key} ? $hash->{$key} : '';
    }
  );
}

=head1 DESCRIPTION

This library provides a common logging interfcaes that expects: Log::Log4perl::Logger or something that extends those features. 

=head1 Get and set log levels

If you want to manualy get/set log levels

  use Log::Log4perl::Level;

  if($self->level!=$WARN) { $self->level($WARN) }

=cut

sub level {
  my ($self,$level)=@_;
  
  if(defined($self->logger)) {
    if(looks_like_number($level)) {
      $self->logger->level($level);
    }
    return $self->logger->level;
  } else {
    return;
  }
}

=head1 OO Methods provided

This class adds the following arguments and accessors to any class that loads using 'with';

  logger:  DOES(Log::Log4perl::Logger)

When the object DOES Log::Log4perl::Logger, the correct Log::Log4perl->get_logger(__PACKAGE__) call will be done.  If you wish to modify the logger method, use an around declaration.  This will keep the trigger $self->_trigger_logger($logger|undef) in tact.

Example:

  around logger=>sub {
    my ($code,$self,$logger)=@_;

    if(defined($logger)) {

      # Do something here
      return $org->($self,$logger);
    } else {
      return $org->($self);
    }
  };


If you wish to just disable the trigger globally, you just disable it using the following flag.

  $Log::LogMethods::SKIP_TRIGGER=1;

=over 4

=cut

has logger=>(
  is=>'rw',
  isa=>sub {
    my ($logger)=@_;
    croak 'argument: logger must DOES(Log::Log4perl::Logger)' unless defined($logger);
    croak 'argument: logger must DOES(Log::Log4perl::Logger)' unless $logger->DOES('Log::Log4perl::Logger')
  },
  trigger=>1,
);

sub _trigger_logger {
  my ($self,$logger)=@_;

  unless(defined($logger)) {
    return undef unless exists $self->{logger};
    return $self->{logger};
  }
  return $logger if $SKIP_TRIGGER;

  if($logger->DOES('Log::Log4perl::Logger')) {
    my $class=blessed $self;
    $class=$self unless defined($class);

    # create our logging class, if we wern't given the one for us
    my $cat=$logger->category;
    $class=~ s/::/./g;
    if($cat ne $class) {
      $self->log_debug("Logger->category eq '$cat', Creating our own: Log::Log4perl->get_logger('$class')");
      my $our_logger=Log::Log4perl->get_logger($class);
      $self->{logger}=$our_logger;
      return $our_logger;
    }
  }

  return $logger;
};

=item * $self->log_error("Some error");

This is a lazy man's wrapper function for 

  my $log=$self->logger;
  $log->log_error("Some error") if $log; 

=cut

sub log_error {
    my ( $self, @args ) = @_;

    $self->log_to_log4perl('ERROR',$self->LOOK_BACK_DEPTH,@args);

}

=item * $log->log_die("Log this and die");

Logs the given message then dies.

=cut 

sub log_die {
    my ( $self, @args ) = @_;

    my $log = $self->logger;
    my @list = ('DIE');
    push @list, $self->log_header if $self->can('log_header');
    return die join(' ',map { defined($_) ? $_ : 'undef'  } @list,@args)."\n"  if $self->log_to_log4perl('ERROR',$self->LOOK_BACK_DEPTH,@args);

    my $string=$self->format_log(@list,@args);

    return die $string  unless $log;

    $self->log_to_log4perl('FATAL',$self->LOOK_BACK_DEPTH,@args);
    die $string;
}

sub format_log {
  my ($self,@args)=@_;

  return join(' ',@args)."\n" unless $self->logger;
  return $self->logger->format_log(@args);

}

=item * $self->log_always("Some msg");

This is a lazy man's wrapper function for 

  my $log=$self->logger;
  $log->log_always("Some msg") if $log; 

=cut

sub log_always {
  my ( $self, @args ) = @_;
  $self->log_to_log4perl('ALWAYS',$self->LOOK_BACK_DEPTH,@args);
}

=item * my $string=$self->log_header;

This is a stub function that allows a quick addin for logging, the string returned will be inserted after the log_level in the log file if this function is created.

=cut

=item * $self->log_warn("Some msg");

This is a lazy man's wrapper function for: 

  my $log=$self->logger;
  $log->log_warn("Some msg") if $log; 

=cut

sub log_warn {
  my ( $self, @args ) = @_;

  $self->log_to_log4perl('WARN',$self->LOOK_BACK_DEPTH,@args);
}

=item * $self->log_info("Some msg");

This is a lazy man's wrapper function for: 

  my $log=$self->logger;
  $log->log_info("Some msg") if $log; 

=cut

sub log_info {
    my ( $self, @args ) = @_;
    $self->log_to_log4perl('INFO',$self->LOOK_BACK_DEPTH,@args);
}

=item * $self->log_debug("Some msg");

This is a lazy man's wrapper function for: 

  my $log=$self->logger;
  $log->log_debug("Some msg") if $log; 

=cut

sub log_debug {
  my ( $self, @args ) = @_;
  $self->log_to_log4perl('DEBUG',$self->LOOK_BACK_DEPTH,@args);
}

=back

=head2 ATTRIBUTES 

Logging attributes can be set for a given function. All logging wrappers autmatically log failed Data::Result objects as log_level ERROR.

=head3 BASIC WRAPPERS

These attributes provide the baseic Starting and Ending log entries for a given function.  

=over 4 

=cut

=item * sub some_method : RESULT_ALWAYS { ... }

Will always produce a start and end log entry 

=item * sub some_method : RESULT_ERROR { ... }

Will always produce a starting and ending log entry at log level ERROR.

=item * sub some_method : RESULT_WARN { ... }

Will always produce a starting and ending log entry at log level WARN.

=item * sub some_method : RESULT_INFO { ... }

Will always produce a starting and ending log entry at log level INFO.

=item * sub some_method : RESULT_DEBUG { ... }

Will always produce a starting and ending log entry at log level DEBUG.

=cut

=back

=head3 BENCHMARKING

Functions can be declared with a given benchmark method. 

=over 4

=item * BENCHMARK_INFO

Declares Start and End log entries for the given function, along with a benchmark timestamp. Benchmark time differences are in microseconds.

=cut


=item * sub method : BENCHMARK_ALWAYS { ... }

Always benchmark this method.

=item * sub method : BENCHMARK_ERROR { ... }

Only benchmark this function if log level is >= ERROR

=item * sub method : BENCHMARK_WARN { ... }

Only benchmark this function if log level is >= WARN

=item * sub method : BENCHMARK_INFO { ... }

Only benchmark this function if log level is >= INFO

=item * sub method : BENCHMARK_DEBUG { ... }

Only benchmark this function if log level is >= DEBUG 

=back

=head1 INTERNAL METHODS

This section documents internal methods.

=over 4

=item * $self->MODIFY_CODE_ATTRIBUTES($code,$att)

Method that generates the wrapper funcitons.

Attrivutes:

  code: glob to overwrite
  att:  The Attribute being overwritten

=cut

sub MODIFY_CODE_ATTRIBUTES {
  my $self=shift;
  my $code=shift;
  return () unless @_;
  my @attr;
  if(my $root=$self->SUPER::can('MODIFY_CODE_ATTRIBUTES')) {
    if($root eq \&MODIFY_CODE_ATTRIBUTES) {
      @attr=@_;
    } else {
      my @list;
      for my $attr (@_) {
        my ($type,$level)=split /_/,$attr;
        if(exists $LEVEL_MAP{$level} and $type=~ m/^(?:BENCHMARK|RESULT)$/s) {
          push @attr,$attr,
        } else {
          push @list,$attr;
        }
      }

      push @attr,$self->$root($code,@list);
    }
  } else {
    @attr=@_;
  }
  my $attr=shift @attr;
  my $trace=$self->strack_trace_to_level(2);
  
  my $gv=svref_2object($code)->GV;
  my $name=$gv->NAME;
  my $tn="${self}::$name";
  $trace->{sub}=$tn;
  $trace->{line}=$gv->LINE;
  my ($type,$level)=split /_/,$attr;
  return ($attr,@attr) unless exists $LEVEL_MAP{$level} and $type=~ m/^(?:BENCHMARK|RESULT)$/s;

  my $lc=lc($type);
  my $method="_attribute_${lc}_common";
  my $target=$code;
  {
    no strict 'refs';
    if(my $nc=\&{$tn} ne $code) {
      # the code we intended to modify was changed
      $target=$nc
    }
  }
  my $ref=$self->$method($trace,$level,$target);
  return (@attr);
}


=item * $self->_attribute_result_common( $stack,$level,$code );

Compile time code, generates basic Startin Finsihed log messages for a given "LEVEL" and also creates ERROR Log entries if the object returned DOES('Data::Result') and is in an error state.

Arguments:

  stack: stack hashref
  level: level(WARN|ALWAYS|INFO|ERROR|TRACE|DEBUG)
  code:  code ref to replcae

=cut

sub _attribute_result_common {
  my ($self,$stack,$level,$code)=@_;

  my $method=$stack->{sub};
  my $ref=sub { 
    use strict;
    use warnings;
    my ($self)=@_;

    my $log=$self->logger;
    my $constant="LOG_$level";

    $self->log_to_log4perl($level,$stack,'Starting');

    my $result;
    if(wantarray) {
      $result=[$code->(@_)];
      if($#{$result}==0) {
        $self->data_result_auto_log_error($stack,$result->[0]);
      }
    } else {
      $result=$code->(@_);
      $self->data_result_auto_log_error($stack,$result);
    }

    $self->log_to_log4perl($level,$stack,'Finished');

    return wantarray ? @{$result} : $result;
  };
  no strict;
  no warnings 'redefine';
  *{$method}=$ref;
  return $ref;
}

=item * $self->_attribute_benchmark_common( $stack,$level,$code);

Compile time code, generates Benchmarking log for a given function: Startin Finsihed log messages for a given "LEVEL" and also creates ERROR Log entries if the object returned DOES('Data::Result') and is in an error state.

Arguments:

  stack: stack hashref
  level: level(WARN|ALWAYS|INFO|ERROR|TRACE|DEBUG)
  code:  code ref to replcae

=cut

sub _attribute_benchmark_common {
  my ($self,$stack,$level,$code)=@_;

  my $method=$stack->{sub};
  my $id=0;
  my $ref=sub { 
    use strict;
    use warnings;
    my ($self)=@_;

    ++$id;
    my $log=$self->logger;

    my $constant="LOG_$level";
    my $t0 = [gettimeofday];
    my $stack={%{$stack}};
    $stack->{recursion_level}=$id;

    $self->log_to_log4perl($level,$stack,'Starting');

    my $result;
    if(wantarray) {
      $result=[$code->(@_)];
      if($#{$result}==0) {
        $self->data_result_auto_log_error($stack,$result->[0]);
      }
    } else {
      $result=$code->(@_);
      $self->data_result_auto_log_error($stack,$result);
    }

    my $elapsed = tv_interval ( $t0, [gettimeofday]);
    $stack->{elapsed}=$elapsed;
    $stack->{kw_elapsed}='elapsed';
    $self->log_to_log4perl($level,$stack,'Finished');

    --$id;

    return wantarray ? @{$result} : $result;
  };
  no strict;
  no warnings 'redefine';
  *{$method}=$ref;
  return $ref;
}

=item * $self->log_to_log4perl($level,$stack,@args)

Low level Automatic logger selection.

Arguments:

  level: Log level (ALWAYS|ERROR|WARN|INFO|DEBUG)
  stack: number or hashref $trace
  args:  argument list for logging

=cut

=item * $self->data_result_auto_log_error($stack,$result);

Creates a required log entry for a false Data::Result object

Arguments: 

  stack:  level or $trace
  result: Object, if DOES('Data::Result') and !$result->is_true a log entry is created

=cut

sub data_result_auto_log_error {
  my ($self,$stack,$result)=@_;
  if(is_blessed_hashref($result)) {
    if($result->DOES('Data::Result')) {
      $self->log_to_log4perl('ERROR',$stack,$result) unless $result->is_true;
    }
  }
}

=item * my $strace=$self->strack_trace_to_level($number)

Given the number, trturns the currect $trace

trace

  sub:      Name of the function
  filename: source file
  package:  Package name
  line:     Line number

=cut

sub strack_trace_to_level {
  my ($self, $level) = @_;

  my $hash = {};
  @{$hash}{qw(package filename line sub)} = caller($level);

  # Look up the stack until we find something that explains who and what called us
  LOOK_BACK_LOOP: while ( defined( $hash->{sub} ) and $hash->{sub} =~ /eval/ ) {

      my $copy = {%$hash};
      @{$hash}{qw(package filename line sub)} = caller( ++$level );

      # give up when we have a dead package name
      unless ( defined( $hash->{package} ) ) {

      $hash = $copy;
      $hash->{eval} = 1;

      last LOOK_BACK_LOOP;
    }
  }

  # if we don't know where we were called from, we can assume main.
  @{$hash}{qw(sub filename package line)} = ( 'main::', $0, 'main', 'undef' )
    unless defined( $hash->{package} );

  $hash->{level}=$level;

  return $hash;
}

=item * if($self->log_to_log4perl($level,$trace,@args)) { ... }

Low Level check and log to log4perl logger object

Arguments:

  level: Log Level (ALWAYS|ERROR|WARN|INFO|DEBUG) 
  trace: level number or $trace
  args:  list of strings to log

=cut 

sub log_to_log4perl {
  my ($self,$level,$trace,@args)=@_;

  my $log=$self->logger;
  return 0 unless defined($log);
  
  my $header=' ';
  $header=' '.$self->log_header.' ' if $self->can('log_header');
  foreach my $value (@args) {
    $value='undef' unless defined($value);
  }

  if(is_plain_hashref($trace)) {

    # this will be modified, so make a copy!
    $trace={%{$trace}};
  } else {
    $trace=$self->strack_trace_to_level($trace);
    $trace->{line}=$self->strack_trace_to_level($trace->{level} -1)->{line};
  }
  
  $trace->{header}=$self->log_header if $self->can('log_header');
  $trace->{msg}=join ' ',@args;

  my $id;
  if(exists $LEVEL_MAP{$level}) {
    $id=$LEVEL_MAP{$level};
  } else {
    $id=$LEVEL_MAP{OFF};
  }
  $CURRENT_CB=$trace;
  $log->log($id,$trace->{msg});
  $CURRENT_CB=undef;
  return 1;
}

=back

=head1 Method Generation

This section documents the code generation methods

=over 4

=item * $self->_create_is_check($name,$level)

Generates the "is_xxx" method based on $name and $level.

Argumetns:

  name:  Human readable word such as: DEBUG
  level: Levels come from Log::Log4perl::Level

=cut

sub _create_is_check {
  my ($self,$name,$level)=@_;

  my $method="is_".lc($name eq 'WARN' ? 'warning' : $name);
  my $code=sub {
    my ($self)=@_;

    my $level=$self->level;
    return 0 unless looks_like_number($level);
    return $level == $Log::LogMethods::LEVEL_MAP{$name};
  };

  no strict;
  no warnings 'redefine';
  eval "*$method=\$code";
}

=item * $self->_create_logging_methods($name,$level)

Generates the logging methods based on $name and $level.

Argumetns:

  name:  Human readable word such as: DEBUG
  level: Levels come from Log::Log4perl::Level

=cut

sub _create_logging_methods {
  my ($self,$name,$level)=@_;
  my $method=lc($name eq 'WARN' ? 'warning' : $name);
  my $code=sub {
    my ($self,@args)=@_;

    my $trace=$self->strack_trace_to_level(2);
    $trace->{line}=$self->strack_trace_to_level($trace->{level} -1)->{line};

    return $self->log_to_log4perl($name,$trace,@args);
  };
  eval "*$method=\$code";
}


while(my ($name,$level)=each %Log::LogMethods::LEVEL_MAP) {
  __PACKAGE__->_create_is_check($name,$level);
  __PACKAGE__->_create_logging_methods($name,$level);
}

=back 

=head2 log level checks

The logging and is_xxx methods are auto generated based on the key/value pairs in %Log::LogMethods::LEVEL_MAP.

=over 4

=item * if($self->is_always) { ... }

=item * if($self->is_error) { ... }

=item * if($self->is_warning) { ... }

=item * if($self->is_info) { ... }

=item * if($self->is_debug) { ... }

=item * if($self->is_default_debug) { ... }

=item * if($self->is_trace) { ... }

=back

=head2 Logging methods

The following methods are autogenerated based on the key/value pairs in %Log::LogMethods::LEVEL_MAP.

=over 4

=item * $self->always("Some log entry")

=item * $self->error("Some log entry")

=item * $self->warning("Some log entry")

=item * $self->info("Some log entry")

=item * $self->debug("Some log entry")

=item * $self->default_debug("Some log entry")

=item * $self->trace("Some log entry")

=back

=head1 AUTHOR

Mike Shipper <AKALINUX@CPAN.ORG>

=cut

1;
