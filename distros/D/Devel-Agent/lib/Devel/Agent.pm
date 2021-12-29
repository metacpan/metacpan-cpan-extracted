package Devel::Agent;

=head1 NAME

Devel::Agent - Agent like debugger interface

=head1 SYNOPSIS

  perl -d:Agent -MDevel::Agent::EveryThing myscript.pl

=head1 DESCRIPTION

For years people in the perl commnity have been asking for a way to do performance monitoring and tracing of runtime production code. This module attempts to fill this role by implementing a stripped down debugger that is intended to provide an agent or agent like interface for perl 5.34.0+ that is simlilar in nature to the agent interface in other langagues Such as python or java.  

This is accomplished by running the script or code in debug mode, "perl -d:Agent"  and then turning the debugger on only as needed to record traching and performance metrics.  That said this module just provides an agent interface, it does not act on code directly until something turns it on.

=cut

use strict;
use warnings;
use 5.34.0;
our $VERSION=.007;

our %VER_FIX;
BEGIN {

  # the only option 
  # for details see perldoc perlvar 
  # and check the $PERLDB section
  my @DEFAULT=(

    # -- this has to be enabled
    # Do not debug
    #0x01,

    # -- this has to be enabled
    # Disable DB::DB 
    #0x02,

    # keep optimizations on
    0x04,

    # do not save extra data
    0x08,

    # don't save line settings
    0x10,

    # -- this has to be enabled
    # disable single step
    #0x20,

    # do not use suroutine address
    0x40,

    # disable goto reporting
    0x80,

    # do not proivde informative file
    0x100,

    # don't bother with informative names
    0x200,

    # do not save source in @{"_<$filename"}
    0x400,

    # do not save evals that generate no subs
    0x800,

    # do not save uncompiled source code
    0x1000,

  );


  $VER_FIX{default}=\@DEFAULT;
  $VER_FIX{'v5.34.0'}=\@DEFAULT;
  my @DB_DISABLE;
  if(exists $VER_FIX{$^V}) {
    @DB_DISABLE=$VER_FIX{$^V}->@*;
  } else {
    @DB_DISABLE=$VER_FIX{default}->@*;
  }

  foreach my $opt (@DB_DISABLE) {
    $^P=$^P & ($^P ^ $opt);
  }
  
}

=head1 Agent interface

The Agent interface is implemented via an on demand debugger that can be turned on/off on the fly.  Also it is possible to run multiple different debugger instances with diffrent configurations on different blocks of code.   This was done intentionally as perl is fairly complex in its nature and an agent interface isn't very useful unless it is flexible.

The agent interface itself is activated by setting $DB::Agent to an instance of itself.

To turn tracing on:

Make sure you either start your perl script -d:Agent or set PERL5OPT="-d:Agent" before launching your script

Inside you script you can issue the following

  use Data::Dumper;

  my $db=DB->new(
    save_to_stack=>1
  );

  $db->start_trace;

  # run some code
  ...

  # and we are done wathcing
  $db->stop_trace;

  # to dump a very human readable full trace
  print Dumper($db->trace);

But altering you code is far from ideal.

Another option is to load the agent and a module that pre-configures it for use such as  the L<Devel::Trace::EveryThing> module, wich provides a stack trace to STDERR in real time as frames begin and exit.

Example using: Devel::Trace::EveryThing

  perl -Ilib -d:Agent -MDevel::Agent::EveryThing examples/everything.pl

=head1 Classes that are Agent Aware

Any class that implements the $instance->___db_stack_filter($agent,$frame,$args,$raw_caller) can filter its own current frame prior to execution, or even prevent the frame from being traced at all.

The ___db_stack_filter method is expected to return true, if the call returns false, then the frame should not be traced. Since the frame passed in before it's runtime execution, the duration value will not be set. 

A basic implementation that exposes only the top level calls is defined in L<Devel::Agent::AwareRole>.  Loading this role into your class will hide all calls made by your class, but not calls made directly to it, this includes child classes that make calls to other classes.

Example:

  package My::Class::That::IS::Mostly::Hidden;

  use Role::Tiny::With; # you can also use Moo Moose or other role implementations
  with 'Devel::Agent::AwareRole';

  1;

If you want to force a class to not show its internals.. say a class like LWP::UserAgent.

  use LWP::UserAgent;
  reuqire Devel::Agent::AwareRole;

  # now only the top level calls to LWP::UserAgent will show up
  *LWP::UserAgent::___db_stack_filter=\&Devel::Agent::AwareRole::___db_stack_filter;

Or if you need to disable filtering on a class that has filtering then you can do the opposite
  
  *LWP::UserAgent::___db_stack_filter=sub { 1}

To be fully ignored

  *LWP::UserAgent::___db_stack_filter=sub { 0}

=head1 Frame information

The following hash represents what is provided as a representation of a frame

  {
    caller_class=>'main',         # class that called this class
    calls=>[],                    # child frames, empty unless $self->save_to_stack is true
    class_method=>'main::test_a', # the resolved class::method
    depth=>1,                     # stack depth, 1 is considered the root
    duration=>undef|Float,        # how long the frame took to execute, only defined when the frame has executed
    end_id=>undef|Int,            # frame final execution order where in the stack it ended 
    line=>2,                      # line number the frame was called from
    no_frame=>0|1,                # when true, this frame would have been filtered but was included for completeness
    order_id=>1,                  # inital frame execution order, where in the stack it started
    owner_id=>0,                  # which order_id frame triggered the execution of this frame
    raw_method=>'main::test_a',   # un-resolved method name
    source=>'test.pl',            # the source file
    t0=>[0,0],                    # Frame Start timestamp in: epoch, microseconds
  }

=head1 DB Constructor options

This section documents the %args the be passed to the new DB(%args) or DB->new(%args) call.  For each option documented in this section, there is an accesor by that given name that can be called by $self->$name($new_value) or my $current_value=$self->$name.

=cut

# prevent indexing ( as ya this will be noticed in the indexing process for sure!!! )
package 
  DB;

#use Modern::Perl;
use strict;
use warnings;
require Scalar::Util;

# as easy as Moo makes things.. its not welcome in a debugger ;(
use Time::HiRes qw(gettimeofday tv_interval);
use B qw(svref_2object);
use Data::Dumper;

our $AGENT;
my $IN_METHOD=0;
my $internals=0;

# ya no, only allow access to this class!!
my %BUILD_ARGS;

# Genrate functions similar to moo and moose, but don't actually use Moo or Moose..
sub has {
  my ($method,%args)=@_;

  my $ref=ref $args{default};
  $BUILD_ARGS{$method}=\%args;
  unless($ref) {
    my $default=$args{default};
    $args{default}=sub { $default };
  }
  if($args{clearer}) {
    my $sub=sub {
       my $self=shift;
      delete $self->{$method};
    };
    my $method="clear_$method";
    my $method_name=__PACKAGE__."::$method";
    no strict 'refs';
    *{$method_name}=$sub;
  }

  my $sub=sub {
    my $self=shift;
    if($#_==-1) {
      if(exists $self->{$method}) {
        return $self->{$method};
      } else {
        my $def=$args{default};
        my $value=$self->{$method}=$self->$def();
        return $value;
      }
    } else {
      return $self->{$method}=$_[0];
    }
  };
  no strict 'refs';
  my $method_name=__PACKAGE__."::$method";
  *{$method_name}=$sub;
}

sub new {
  my ($class,%args)=@_;
  my $self=bless {},$class;
  while(my ($key,$args)=each %BUILD_ARGS) {
    if(exists $args{$key}) {
      $self->{$key}=$args{$key};
    } elsif(!$args->{lazy}) {
      my $cb=$args->{default};
      $self->{$key}=$self->$cb();
    }
  }

  # force out what pid and tid we are from
  $self->pid;
  $self->tid;
  return $self;
}

#use constant DEFAULT_DEPTH=>4;
# use prototype to declare constant
sub DEFAULT_DEPTH () { 4 }

our @EXCLUDE_DEFAULTS=(
  __PACKAGE__,
  qw(
    Data::Dumper
    Time::HiRes
    Method::Generate::Accessor
    MooX::Types::MooseLike
    Method::Generate::Accessor::_Generated
    Moo::HandleMoose::AuthorityHack
    Method::Generate::Constructor
    Sub::Quote
    strict
    warnings
    Sub::Defer
    B
  )
);

=over 4

=item * level=>ArrayRef

This is an auto generated array ref that is use by the internals to track current stack level state information.

=cut

has level=>(
  is=>'rw',
  #isa=>ArrayRef,
  lazy=>1,
  default=>sub { [] },
  clearer=>1,
);

=item * resolve_constructor=>Bool

This option is used to turn on or off the resolution of a class name when being constructed and other situations.  By default this option is set to true.

=cut

has resolve_constructor=>(
# isa=>Bool,
  is=>'ro',
  default=>1,
);

=item * trace=>[]

When the object instance is constructed with save_to_stack=>1 ( default is: 0 ) then the stack trace will be saved into a single multi tier data structrure represented by $self->trace.

=cut

has trace=>(
# isa=>ArrayRef,
  is=>'rw',
  default=>sub {
    return [];
  },
  lazy=>1,
  clearer=>1,
);

=item * ignore_calling_class_re=>ArrayRef[RegexpRef]

This option allows a list of calling calsses to be ignored when they match the regular expression.

Example ignore_calling_class_re being set to [qr{^Do::Not::Track::Me::}] will prevent the debugger for trying to trace or record calls made by any methods within "Do::Not::Track::Me::".  This does not prevent this class from showing up fully ina stack trace.  If this class calls a class that calls another class that calls a class unlisted in ignore_calling_class_re, then Do::Not::Track::Me::xxx will show up as the owner frame of the calls as a biproduct of correctness in stack tracing.

=cut

has ignore_calling_class_re=>(
# isa=>ArrayRef[RegexpRef],
  is=>'ro',
  default=>sub {
    return [];
  },
);

=item * excludes=>HashRef[Int]

This is a collection of classes that should be ignored when they make calls. The defaults are defined in @DB::EXCLUDE_DEFAULTS and include classes like Data::Dumper and Time::HiRes to name a few.  For a full list of the current defaults just perl -MDevel::Agent -MData::Dumper -e 'print Dumper(\@DB::EXCLUDE_DEFAULTS)'

=cut

has excludes=>(
# isa=>HashRef[Int],
  is=>'ro',
  default=>sub {
    return { 
      map {($_,1)}  
      @EXCLUDE_DEFAULTS
    }
  },
);

=item * last_depth=>Int

This value is used at runtime to determine the previous point in the stack trace.

=cut

has last_depth=>(
  default=>0,
  lazy=>1,
  is=>'rw',
  clearer=>1,
# isa=>Int,
);

=item * depths=>ArrayRef

This is used at runtime to determin the current frame stack depth.  Each currently executing frame is kept in order from top to the bottom of the stack.

=cut

has depths=>(
  is=>'rw',
  lazy=>1,
# isa=>ArrayRef,
  clearer=>1,
  default=>sub { return [] },
);

=item * order_id=>Int

This option acts as the sequence or order of execution counter for frames.  When a frame starts $self->order_id is incremented by 1 and set to the frame's oder_id when the frame has completed execution the current $self->order_id is incremented again and set to the frame's end_id.

=cut

has order_id=>(
# isa=>Int,
  is=>'rw',
  lazy=>1,
  default=>0,
  clearer=>1,
);

=item * save_to_stack=>Bool

This option is used to turn on or of the saving of frames details in to a layered structure inside of $self->trace.  The default is 0 or false.

=cut

has save_to_stack=>(
# isa=>Bool,
  is=>'rw',
  default=>0,
);

=item * on_frame_end=>CodeRef

This code ref is called when a frame is closed.  This should act as the default data streaming hook callback.  All tracing operations are halted durriong this callback.

Example:

  sub {
    my ($self,$last)=@_;

    # $self: An instance of DB
    # $last: The most currently closed frame
  }

=cut

has on_frame_end=>(
# isa=>CodeRef,
  is=>'rw',
  default=>sub { sub {} },
);

=item * trace_id=>Int

This method provides the current agent tracing pass.  This number is incremented at the start of each call to $self->start_trace.

=cut

has trace_id=>(
  is=>'rw',
  default=>0,
  lazy=>1,
);

=item * ignore_blocks=>HasRef[Int]

This hashref reprents what perl phazed blocks to ignore, the defaults are.

  {
    BEGIN=>1, 
    END=>1,  
    INIT=>1,
    CHECK=>1,
    UNITCHECK=>1,
  }

The default values used to generate the hashref contained in in @DB::@PHAZES

=cut

our @PHAZES=(qw(BEGIN  END  INIT  CHECK  UNITCHECK));

has ignore_blocks=>(
  #isa=>HashRef[Int],
  is=>'ro',
  default=>sub {
    return { map { ($_,1) } @PHAZES}
  },
);

=item * constructor_methods=>HashRef[Int]

This is a hash of method names we consider object constructors

Default: 

  {
    # we assume new is an object constructor
    new=>1
  }

=cut

has constructor_methods=>(
  is=>'ro',
  #isa=>HashRef,
  default=>sub {
    return { 
     new=>1,
    };
  }
);

=item * max_depth=>Int

When the value is set to something other than -1, the number represents the maxium stack depth to trace too. Once the frame of max_depth exits, then max_depth will again be set to -1.

=cut

has max_depth=>(
  is=>'rw',
  lazy=>1,
  clearer=>1,
  default=>-1,
);

=item * tid=>Int

This is mostly here for completeness, retuns the tid id this debugger was created in. 

Note Note Note:

The code was not orginally develpoed without threading in mind, if you wish to trace elemetns within a thread make sure you start an instance of the debugger within that thread.

=cut

has tid=>(
  is=>'rw',
  clearer=>1,
  default=>sub {
    my $tid=1;
    eval { 
     if(my $cb=threads->can('tid')) {
       $tid=threads->$cb();
     }
    };
    return $tid;
  },
);

=item * agent_aware=>Bool

This enables or disables the use of $self->_agent_aware(...) method.  See: $self->_agent_aware.  Default is true.

=cut

has agent_aware=>(
  is=>'ro',
  default=>1,
  #isa=>Bool,
);

=item * existing_trace=>Maybe[InstanceOf['DB']]

This acts as a save point for another existing trace to be exected.

=cut

has existing_trace=>(
  is=>'rw',
  #isa=>Maybe[InstanceOf['DB']],
  lazy=>1,
  clearer=>1,
  default=>sub { undef },
);

=item * process_result=>CodeRef

This callback can be used to evaluate/modify the results of a traced method in this callback.

Example callback

  sub {
    my ($self,$type,$frame)=@_;
    # $self:  Instance of Devel::Agent
    # $type:  -1,0,1
    # $frame: The current frame
  }

Notes on $type and where the current return values are stored

When $type is:
  -1 This is in a call to DESTROY( the envy of the programming world! )
    Return value is in $DB::ret

  0  This method was called in a scalar context
    Return value is in $DB::ret

  1  This method was called in a list context
    Return value is in @DB::ret

=cut

has process_result=>(
  is=>'ro',
  #isa=>CodeRef,
  default=>sub { sub {} },
);

=item * filter_on_args=>CodeRef

This allows a code ref to be passed in to filter arguments passed into a method.  If the method returns false, the frame is ignored.

Default always returns true

  sub  { 
    my ($self,$frame,$args,$caller)=@_;
    # $self:   Instance of Devel::Agent
    # $frame:  Current frame hashref
    # $args:   The @_ contents
    # $caller: The contents of caller($depth)
    return 1; 
  }

This is more or less a global frame filter, see: Classes that are Agent Aware

=cut

has filter_on_args=>(
  is=>'ro',
  #isa=>CodeRef,
  default=>sub { sub {1} },
);


=item * pid=>Int

By default this is set to $$

=cut

has pid=>(
  is=>'ro',
  default=>$$,
  #isa=>Int,
);

=back

=head1 API Methods

This section documents general api methods.

=head2 Bool=$self->_filter($caller,$args)

This method is the core interface used to decide if a method should show up in the debug/stack trace.

This is where the following constructor options are applied:

=over 2

=item * ignore_calling_class_re

The $self->ignore_calling_class_re is applied to each calling or caller->[0], if it matches the frame is ignored.

=item * excludes

If $caller->[0] matches an element of excludes, then this frame is ignored.

=item * resolve_constructor

This converts the "class" portion of the frame value class_method to the first argument of a method that matches anything found in resolve_constructor.

=item * excludes

The updated class value is applied to excludes again, if it matches, then the frame is not traced.

=back

=cut

sub _filter {
  my ($self,$caller,$args)=@_;
  
  return 0 unless defined($caller->[0]);
  foreach my $re ($self->{ignore_calling_class_re}->@*) {
    if($caller->[0]=~ $re) {
      return 0;
    }
  }
  return 0 if exists $self->{excludes}->{$caller->[0]};
  my $caller_class=$caller->[3];
  return 0 unless defined $caller_class;

  my ($class,$method)=$caller_class=~ m/^(.*)::(.*)$/;

  $self->resolve_class($class,$method,$caller,$args);

  return 0 if exists $self->{excludes}->{$class};
  return 1;
}

=head2 $self->resolve_class($class,$method,$caller,$args)

Changes $class to the constructor class if $self->resolve_constructor && exists $self->constructor_methods->{$method} 

=cut

sub resolve_class {
  my ($self,$class,$method,$caller,$args)=@_;
  return unless $#{$args}!=-1 && defined($args->[0]);

  if($self->{resolve_constructor} && exists $self->{constructor_methods}->{$method} ) {
    my $new_class=$args->[0];
    if($new_class->DOES($class)) {
      $caller->[3]=$class.'::'.$method;
      $_[1]=$new_class;
    }
  }
}

=head2 $self->close_depth($depth)

After a frame ahs finished execution, this method is called.  This removes the frame from $self->depths

Sets the following frame option:

  error     the $@ state
  end_id    the order_id this frame ended on
  duration  Execution time in micro seconds

=cut

sub close_depth {
  my ($self,$depth)=@_;

  my $last=pop $self->{depths}->@*;
  my $t0=$last->{t0};
  my $d=tv_interval($t0);
  $d=0 if index($d,'e')!=-1; # how is this slower than a regex? wow!!!
  #$d=0 if $d=~ /e/s;
  $last->{duration}=$d;
  $last->{end_id}=$self->next_order_id,
  my $tmp=$internals;
  $internals=1;
  $self->{on_frame_end}->($self,$last);
  $internals=$tmp;
}

=head2 my $id=$self->next_order_id

Returns the next order_id.

=cut

sub next_order_id {
  my ($self)=@_;
  return $self->{order_id}=1+$self->{order_id};
}

=head2 $self->close_to($depth,$frame|undef)

Closes down the stack trace to $depth, performs addtional actions if $frame is defiend.

=cut

sub close_to {
  my ($self,$to,$last)=@_;

  if($to<=$self->{max_depth}) {
    # reset our max depth to -1;
    $self->{max_depth}=-1;
  }

  my $target;
  my $size=$self->{depths}->$#*;
  for(my $depth=$size;$depth>0;--$depth) {
    if($depth==$to) {
      $self->close_depth($depth);
      $target=$to;
      last; 
    } elsif($depth < $to) {
      $target=$depth;
      last;
    } else {
      $self->close_depth($depth);
    }
  }
  if(defined($target)) {
    $self->save_to($last) if defined($last);
  } elsif(defined($last)) {
    $self->save_to($last);
  }
  $self->{last_depth}=$to;
}

=head2 $self->filter($caller,$args)

This method is called by the DB method after the sub method and is used to place a frame on the stack for tracing.

=cut

sub filter{
  my ($self,$caller,$args)=@_;

  $self->pause_trace;
  my $raw_caller=[@$args];
  return $self->restore_trace unless $self->_filter($caller,$args);
  my $last=$self->caller_to_ref($caller,undef,$DB::sub,0);
  return $self->restore_trace unless defined($last);

  unless($self->{filter_on_args}->($self,$last,$args,$raw_caller)){
    $self->restore_trace;
    return;
  }

  if($self->{agent_aware}) {
    unless($self->_agent_aware($last,$args,$raw_caller)) {
      $self->restore_trace;
      return;
    }
  }

  $self->push_to_stack($last);
  my $level=$self->{level};
  push $level->[$level->$#*]->@*,$self->{last_depth};
  $self->restore_trace;
}

=head2 $self->_agent_aware($frame,$args,$raw_caller)

This method is called before a frame is traced if $self->agent_aware is set to true( the default ).  The objective of this method is see of the first argument being passed to this method is a blessed instance of that class.  When the first argument passed to the class is a blessed object that DOES this class then a call to $args->[0]->___db_stack_filter($agent,$frame,$args,$raw_caller) is made.  This allows classes to modify or inspect the frame that will be used in the reace.  If the call to $args->[0]->___db_stack_filter($agent,$frame,$args,$raw_caller)  returns false, the frame is skipped durring the trace period.

Note note Note:

The call to $args->[0]->___db_stack_filter($agent,$frame,$args,$raw_caller) is never wrapped in a eval and should never do anything heavy or it will impact the metrics provided by the debugger.

=cut

sub _agent_aware {
  my ($self,$frame,$args,$raw_caller)=@_;
  
  return 1 unless $args->$#*>-1 && defined($args->[0]);
  my $class=&Scalar::Util::blessed($args->[0]);
  return 1 unless $class;
  my $cb=$class->can('___db_stack_filter');
  return 1 unless $cb;

  if($frame->{class_method}=~ /^(.*)::/s) {
    return 1 unless $args->[0]->DOES($1);
    return $args->[0]->$cb(@_);
  }

  return 1;
}

=head2 Self->save_to($frame)

Saves the frame to the stack trace at the proper depth.

=cut

sub save_to {
  my ($self,$last)=@_;
  
  my $depth=$last->{depth};
  $self->{depths}->[$depth]=$last;

  $self->{last_depth}=$depth;
  # stop here unless someone wants the frames saved in memory
  return unless $self->save_to_stack;
  if($depth==1) {
    push $self->trace->@*,$self->{depths}->[$depth]=$last;
  } else {
    my $root=$depth -1;
    push $self->{depths}->[$root]->{calls}->@*,$self->{depths}->[$depth]=$last;
  }
}

=head2 $self->push_to_stack($frame)

This method handles the saving, closing and backfilling logic for a given frame.

=cut

sub push_to_stack {
  my ($self,$last)=@_;

  my $depth=$last->{depth};
  my $last_depth=$self->{last_depth};
  if($last_depth==0) {
    $self->save_to($last);
  } elsif($depth<= $last_depth) {
    $self->close_to($depth,$last);
  } else {
    $self->save_to($last);
  }
}

=head2 my $depth=$self->get_depth

Returns undef or a number representing the stack depth.  When the value is undef, the trace would exceed $self->max_depth;

=cut

sub get_depth {
  my ($self)=@_;
  my $start = DEFAULT_DEPTH;
  # skip un-needed depth checking
  $start +=$self->{depths}->$#* if $self->{depths}->$#* >0;
  my $depth=$start - DEFAULT_DEPTH;

  my $caller=[caller($start)];
  my $no_frame=[];
  my $max=$self->{max_depth};
  while($caller->$#*!=-1) {
    if($max!=-1) {
      my $pos=$depth +1;
      if($pos>$max) {
        return undef;
      }
    }

    if($start !=DEFAULT_DEPTH) {
      unless(defined $self->{depths}->[$depth]) {
        push $caller->@*,$depth;
        push $no_frame->@*,$caller;
      }
    }
    ++$start;
    $caller=[caller($start)];
    $depth=$start - DEFAULT_DEPTH;
  }
  foreach my $caller ($no_frame->@*) {
    my $depth=pop $caller->@*;
    my $last=$self->caller_to_ref($caller,$depth,$caller->[3],1);
    $self->push_to_stack($last);
  }
  return $start - DEFAULT_DEPTH;
}

=head2 my $frame=$self->caller_to_ref($caller,$depth|undef,$raw_method,$no_frame)

Returns a frame hashref.  If $depth is not defined a call to $depth is made, if it exceeds a set value of $self->max_depth undef is returned.

=cut

sub caller_to_ref {
  my ($self,$caller,$depth,$raw_method,$no_frame)=@_;
  $no_frame=0 unless defined($no_frame);
  my ($p,$f,$l,$s,$h,$w,$e,$r)=@$caller;
  if(defined($e)) {
    $e='...';
  }
  if ($r) {
    $s = "require '$e'";
  } elsif (defined $r) {
    $s = "eval '$e'";
  } elsif ($s eq '(eval)') {
     $s = "eval {...}";
  }
  $f = "$f" unless $f eq '-e';

  $depth=$self->get_depth unless defined($depth);
  unless(defined($depth)) {
    return undef;
  }

  my $root=$depth -1;
  my $owner_id=0;
  if($root!=0 && defined $self->{depths}->[$root]) {
    $owner_id=$self->{depths}->[$root]->{order_id};
  }
  
  my $ref={ 
    raw_method=>(ref($raw_method) ? 'sub { ... }' : $raw_method ),
    owner_id=>$owner_id,
    depth=>$depth,
    order_id=>$self->next_order_id,
    calls=>[],
    t0=>[gettimeofday],
    #t0=>[time,0],
    class_method=>$s,
    source=>$f,
    line=>$l,
    caller_class=>$p,
    no_frame=>$no_frame,
    meta=>{},
    end_id=>0,
  };

  return $ref;
}

=head2 $self->reset

Rsets the internals of the object for starting a new stack trace.

=cut

sub reset {
  my ($self)=@_;
  foreach my $key (
  qw(
  trace
  last_depth
  depths
  order_id
  level
  tid
  max_depth
  existing_trace
  )) {
    my $method="clear_$key";
    $self->$method();
    $self->$key();
  }
}

=head2 $self->start_trace

Begins the stack trace process.

=cut

sub start_trace {
  my ($self)=@_;
  $self->reset;
  if(defined($AGENT)) {
    $self->existing_trace($AGENT);
    $AGENT->pause_trace;
  }
  $self->trace_id($self->trace_id +1);
  $AGENT=$self;
}


=head2 $self->stop_trace

Ends the current stack trace process.

=cut

sub stop_trace {
  my ($self)=@_;
  $self->close_to(1);
  $AGENT=undef;
  $AGENT=$self->existing_trace();
  if(defined($AGENT)) {
    $AGENT->resume_trace;
  }
}

=head2 $self->pause_trace

Turns tracing off until a call to $self->restore_trace is made

=cut

sub pause_trace {
  my ($self)=@_;
  $AGENT=undef;
  $IN_METHOD=0;
}

=head2 $self->restore_trace

Turns tracking back on.

=cut

sub restore_trace {
  my ($self)=@_;
  $AGENT=$self;
}

=head2 $self->close_sub($res)

This method is called by the sub method.  It is used to send notice that a frame has finished execution.

=cut

sub close_sub {
  my ($self,$res)=@_;
  $self->pause_trace;
  my $level=pop $self->{level}->@*;

  if($level->$#*==0) {
    $self->restore_trace;
    return;
  }
  my $depth=$level->[1];
  my $last=$self->{depths}->[$depth];
  $self->close_to($depth);
  $self->{process_result}->($self,$res,$last);
  $self->restore_trace;
}

=head2 my $frames=$self->grab_missing($depth,$frame);

Returns any skiped frames between $depth and $frame.

$depth is expected to be a number and $frame expected to be a frame hash.

=cut

sub grab_missing {
  my ($self,$depth,$frame)=@_;
  my $missing=[];

  $depth=1 if $depth <1;

  return $missing if $depth > $frame->{depth};
  # stop here if these are both the same depth
  return $missing if($depth==$frame->{depth});

  for(;$depth<$frame->{depth};++$depth) {
    push $missing->@*,$self->{depths}->[$depth];
  }
  return $missing;
}

=head2 DB(@_)

This method is manditory for the implemntation of a debugger.  With the current perl internals it is called every time a breakable point of code is reached. Unfortunatly this overhead is unavoidable. 

Example:

  foreach(1,3,4) { # Debugger would normally stop here
    someMethod($_)  # agent tracing only happens when your function is called
  }

  # total calls would be 4 + 3 * 2
  # 1 call when foreach is reached
  # 1 call for each element in the loop
  # 2 times for every method

The as an optimization the agent ensures that tracing only happens on user defined functions. All other operations should be ignored.

The optimization reduces the number of calls to 3 or just once per method.

=cut

sub DB {
  return unless $IN_METHOD;
  $IN_METHOD=0;
  $AGENT->filter([caller 1],\@_);
}

=head2 sub(@_)

THis is a manditory for implementation, this method is called twice per user defined method.  Once before the execution once to actually run the function.

Example:

  foreach(1,3,4) { 
    someMethod($_)  # sub is called 2 times per function
  }

  # calls to sub 6

If $AGENT is undef, this method does nothing.

=cut

sub sub {
  if($IN_METHOD 
    || !defined($AGENT) 
    || $internals 
    || substr($DB::sub,0,4) eq 'DB::' 
    || ${^GLOBAL_PHASE} ne 'RUN'
  ) {
    no strict 'refs';
    return &$DB::sub 
  }
  
  
  if(ref($DB::sub)) {
    my $name=svref_2object($DB::sub)->GV->NAME;
    if(defined($name) && exists $AGENT->{ignore_blocks}->{$name}) {
      my $agent=$AGENT;
      $IN_METHOD=0;
      $AGENT=undef;
      if(wantarray) {
        @DB::ret = &$DB::sub;
        $AGENT=$agent;
        my @list=@DB::ret;
        @DB::ret=();
        return @list;
      } else {
        $DB::ret = &$DB::sub;
        $AGENT=$agent;
        return $DB::ret;
      }
    }
  }
  push $AGENT->{level}->@*,[$DB::sub];

  $IN_METHOD=1;
  
  no strict 'refs';
  if ($DB::sub eq 'DESTROY' or substr($DB::sub, -9) eq '::DESTROY' or not defined wantarray) {
    $DB::ret=&$DB::sub;
    $AGENT->close_sub(-1) if defined $AGENT;
    $DB::ret = undef;
  } elsif (wantarray) {
    @DB::ret = &$DB::sub;
    $AGENT->close_sub(1) if defined $AGENT;
    @DB::ret;
  } else {
    $DB::ret = &$DB::sub;
    $AGENT->close_sub(0) if defined $AGENT;
    $DB::ret;
  }
}

sub DESTROY {
  my ($self)=@_;
  $self->reset;
}

1;

__END__

=head1 Compile time notes

For perl 5.34.0+

When loading this moduel All features of the debugger are disabled aside from: ( 0x01, 0x02, and 0x20 ) which are requried to force the execution of DB::DB. Please see the perldoc perlvar and the $PERLDB section.

  Which means:    $^P==35

=head1 RUNTIME

At runtime, this modue tries to exectue $Devel::Agent::AGENT->filter($caller,$args).  If $Devel::Agent::AGENT is not defined, then nothing happens.

  $caller: is the caller information
  $args:   contains an array reference that represents the arguments passed to a given method

=head1 TODO

  1. Add Dancer2 trace implementation/example

=head1 AUTHOR

Michael Shipper L<AKALINUX@CPAN.ORG>

=head1 Silly stuff

Please forgive the typos, this was written on holiday in my spare time.

=head1 LICENSE

This code is released under the terms of the perl5 licence itself.  Please see LICENSE.md for more details.

=head1 See Also

Lots of these internals are based on the following:

L<DB>,L<Devel::Trace>,L<perldebguts>

=cut

