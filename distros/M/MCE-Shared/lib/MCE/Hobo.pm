###############################################################################
## ----------------------------------------------------------------------------
## A threads-like parallelization module.
##
###############################################################################

package MCE::Hobo;

use strict;
use warnings;

use 5.010001;

no warnings qw( threads recursion uninitialized once redefine );

our $VERSION = '1.826';

## no critic (BuiltinFunctions::ProhibitStringyEval)
## no critic (Subroutines::ProhibitExplicitReturnUndef)
## no critic (Subroutines::ProhibitSubroutinePrototypes)
## no critic (TestingAndDebugging::ProhibitNoStrict)

use Carp ();

my ($_has_threads, $_freeze, $_thaw);

BEGIN {
   local $@;

   if ($^O eq 'MSWin32' && !$INC{'threads.pm'}) {
      eval 'use threads; use threads::shared';
   }
   elsif ($INC{'threads.pm'} && !$INC{'threads/shared.pm'}) {
      eval 'use threads::shared';
   }

   $_has_threads = $INC{'threads.pm'} ? 1 : 0;

   if (!exists $INC{'PDL.pm'}) {
      eval '
         use Sereal::Encoder 3.015 qw( encode_sereal );
         use Sereal::Decoder 3.015 qw( decode_sereal );
      ';
      if ( !$@ ) {
         my $_encoder_ver = int( Sereal::Encoder->VERSION() );
         my $_decoder_ver = int( Sereal::Decoder->VERSION() );
         if ( $_encoder_ver - $_decoder_ver == 0 ) {
            $_freeze = sub { encode_sereal( @_, { freeze_callbacks => 1 } ) };
            $_thaw   = \&decode_sereal;
         }
      }
   }

   if (!defined $_freeze) {
      require Storable;
      $_freeze = \&Storable::freeze;
      $_thaw   = \&Storable::thaw;
   }

   return;
}

## POSIX.pm is a big module. The following constant covers most platforms.
use constant { _WNOHANG => $^O eq 'solaris' ? 64 : 1 };

use Time::HiRes qw(sleep);
use bytes;

use MCE::Shared ();

use overload (
   q(==)    => \&equal,
   q(!=)    => sub { !equal(@_) },
   fallback => 1
);

my $_tid = $_has_threads ? threads->tid() : 0;
my $_lock : shared = 1;

sub import {
   no strict 'refs'; no warnings 'redefine';
   *{ caller().'::mce_async' } = \&async;

   return;
}

sub CLONE {
   $_tid = threads->tid() if $_has_threads;
}

###############################################################################
## ----------------------------------------------------------------------------
## 'new', 'async (mce_async)', and 'create' for threads-like similarity.
##
###############################################################################

my ( $_LIST, $_STAT, $_DATA ) = ( {}, {}, {} );

bless my $_SELF = { MGR_ID => "$$.$_tid", WRK_ID => $$ }, __PACKAGE__;

## 'new' and 'tid' are aliases for 'create' and 'pid' respectively.

*new = \&create, *tid = \&pid;

## Use "goto" trick to avoid pad problems from 5.8.1 (fixed in 5.8.2)
## Tip found in threads::async.

sub async (&;@) {
   unless ( defined $_[0] && $_[0] eq 'MCE::Hobo' ) {
      unshift @_, 'MCE::Hobo';
   }
   goto &create;
}

sub create {
   my $mgr_id = "$$.$_tid";
   my $pkg    = caller() eq 'MCE::Hobo' ? caller(1) : caller();
   my ( $class, $self, $func );

   if ( ref($_[1]) eq 'HASH' ) {
      ( $class, $self, $func ) = ( shift, shift, shift );
   } else {
      $self = {}, ( $class, $func ) = ( shift, shift );
   }

   $self->{MGR_ID} = $mgr_id;

   bless $self, $class;

   ## error checking and setup

   if ( ref($func) ne 'CODE' && !length($func) ) {
      return $self->_error("code function is not specified or valid\n");
   }

   $func = $pkg.'::'.$func if ( !ref($func) && index($func,':') < 0 );

   if ( !exists $self->{posix_exit} ) {
      $self->{posix_exit} = 1 if (
         ( $_has_threads && $_tid ) || $INC{'Mojo/IOLoop.pm'} ||
         $INC{'Curses.pm'} || $INC{'CGI.pm'} || $INC{'FCGI.pm'} ||
         $INC{'Prima.pm'} || $INC{'Tk.pm'} || $INC{'Wx.pm'} ||
         $INC{'Gearman/Util.pm'} || $INC{'Gearman/XS.pm'}
      );
   }

   if ( !exists $_LIST->{$pkg} ) {
      $_LIST->{$pkg} = MCE::Hobo::_ordhash->new;            # non-shared
   }

   if ( !exists $_DATA->{$pkg} ) {
      $_DATA->{$pkg} = MCE::Hobo::_hash->new;               # non-shared
      $_STAT->{$pkg} = MCE::Hobo::_hash->new;
   }

   if ( !$_DATA->{$pkg}->exists($mgr_id) ) {
      $_DATA->{$pkg}->set( $mgr_id, MCE::Shared->share(MCE::Hobo::_hash->new) );
      $_STAT->{$pkg}->set( $mgr_id, MCE::Shared->share(MCE::Hobo::_hash->new) );

      $_STAT->{$pkg}->set("$mgr_id:seed", int(rand() * 1e9) );
      $_STAT->{$pkg}->set("$mgr_id:id", 0 );

      $_LIST->{$pkg}->clear();
   }

   ## spawn a hobo process

   my $seed = $_STAT->{$pkg}->get("$mgr_id:seed");
   my $id   = $_STAT->{$pkg}->incr("$mgr_id:id");

   lock($_lock), sleep(0.01) if ($_tid && $^O eq 'netbsd');

   _dispatch( $self, $pkg, $seed, $id, $mgr_id, $func, @_ );
}

###############################################################################
## ----------------------------------------------------------------------------
## Public methods.
##
###############################################################################

sub equal {
   return 0 unless ( ref($_[0]) && ref($_[1]) );
   $_[0]->{WRK_ID} == $_[1]->{WRK_ID} ? 1 : 0;
}

sub error {
   _croak('Usage: $hobo->error()') unless ref($_[0]);
   $_[0]->join() unless exists( $_[0]->{JOINED} );
   $_[0]->{ERROR} || undef;
}

sub exit {
   shift if ( defined $_[0] && $_[0] eq 'MCE::Hobo' );

   my ($self) = ( ref($_[0]) ? shift : $_SELF );
   my $mgr_id = $self->{MGR_ID};
   my $wrk_id = $self->{WRK_ID};

   if ( $wrk_id == $$ ) {
      $_[0] ? die "Hobo exited ($_[0])\n" : die "Hobo exited (0)\n";
      _exit(); # not reached
   }
   elsif ( $mgr_id eq "$$.$_tid" ) {
      return $self if ( exists $self->{JOINED} );
      sleep 0.015 until $_STAT->{ caller() }->get($mgr_id)->exists($wrk_id);

      if ($^O eq 'MSWin32') {
         CORE::kill('KILL', $wrk_id) if CORE::kill('ZERO', $wrk_id);
      } else {
         CORE::kill('QUIT', $wrk_id) if CORE::kill('ZERO', $wrk_id);
      }

      $self;
   }
   else {
      CORE::exit(@_);
   }
}

sub finish {
   _croak('Usage: MCE::Hobo->finish()') if ref($_[0]);
   my $pkg = ( defined $_[1] ) ? $_[1] : caller;

   _notify() if ( exists $_SELF->{_pkg} );

   if ( $pkg eq 'MCE' ) {
      for my $k ( keys %{ $_LIST } ) { MCE::Hobo->finish($k); }
   }
   elsif ( exists $_LIST->{$pkg} ) {
      return if $MCE::Signal::KILLED;

      my $mgr_id = "$$.$_tid";

      if ( exists $_DATA->{$pkg} && $_DATA->{$pkg}->exists($mgr_id) ) {
         my $count = 0;

         if ( $_LIST->{$pkg}->len ) {
            sleep 0.1;

            for my $hobo ( $_LIST->{$pkg}->vals ) {
               if ( $hobo->is_running ) {
                  CORE::kill('KILL', $hobo->pid)
                     if CORE::kill('ZERO', $hobo->pid);

                  $count++;
               }
            }
         }

         warn "Finished with active Hobos ($count)\n"
            if ($count && $^O ne 'MSWin32');

         $_DATA->{$pkg}->del( $mgr_id )->destroy;
         $_STAT->{$pkg}->del( $mgr_id )->destroy;

         $_STAT->{$pkg}->del("$mgr_id:seed");
         $_STAT->{$pkg}->del("$mgr_id:id");
      }

      delete $_LIST->{$pkg};
   }

   @_ = ();

   return;
}

sub is_joinable {
   _croak('Usage: $hobo->is_joinable()') unless ref($_[0]);

   my ($self) = @_;
   my $mgr_id = $self->{MGR_ID};
   my $wrk_id = $self->{WRK_ID};

   if ( $wrk_id == $$ ) {
      '';
   }
   elsif ( $mgr_id eq "$$.$_tid" ) {
      return undef if ( exists $self->{JOINED} );
      local ($!, $?); ( waitpid($wrk_id, _WNOHANG) == 0 ) ? '' : 1;
   }
   else {
      $_DATA->{ caller() }->get($mgr_id)->exists($wrk_id) ? 1 : '';
   }
}

sub is_running {
   _croak('Usage: $hobo->is_running()') unless ref($_[0]);

   my ($self) = @_;
   my $mgr_id = $self->{MGR_ID};
   my $wrk_id = $self->{WRK_ID};

   if ( $wrk_id == $$ ) {
      1;
   }
   elsif ( $mgr_id eq "$$.$_tid" ) {
      return undef if ( exists $self->{JOINED} );
      local ($!, $?); ( waitpid($wrk_id, _WNOHANG) == 0 ) ? 1 : '';
   }
   else {
      $_DATA->{ caller() }->get($mgr_id)->exists($wrk_id) ? '' : 1;
   }
}

sub join {
   _croak('Usage: $hobo->join()') unless ref($_[0]);

   my ($self) = @_;

   if ( exists $self->{JOINED} ) {
      return ( defined wantarray )
         ? wantarray ? @{ $self->{RESULT} } : $self->{RESULT}->[-1]
         : ();
   }

   my $mgr_id = $self->{MGR_ID};
   my $wrk_id = $self->{WRK_ID};
   my $pkg    = caller() eq 'MCE::Hobo' ? caller(1) : caller();

   if ( $wrk_id == $$ ) {
      _croak('Cannot join self');
   }
   elsif ( $mgr_id eq "$$.$_tid" ) {
      local ($!, $?); waitpid($wrk_id, 0);
      $_LIST->{$pkg}->del($wrk_id);
   }
   else {
      sleep 0.3 until ( $_DATA->{$pkg}->get($mgr_id)->exists($wrk_id) );
   }

   my $result = $_DATA->{$pkg}->get($mgr_id)->del($wrk_id);

   $self->{RESULT} = ( defined $result ) ? $_thaw->($result) : [];
   $self->{ERROR}  = $_STAT->{$pkg}->get($mgr_id)->del($wrk_id);
   $self->{JOINED} = 1;

   ( defined wantarray )
      ? wantarray ? @{ $self->{RESULT} } : $self->{RESULT}->[-1]
      : ();
}

sub kill {
   _croak('Usage: $hobo->kill()') unless ref($_[0]);

   my ( $self, $signal ) = @_;
   my $mgr_id = $self->{MGR_ID};
   my $wrk_id = $self->{WRK_ID};
   my $pkg    = caller;

   if ( $wrk_id == $$ ) {
      CORE::kill($signal || 'INT', $$);
   }
   elsif ( $mgr_id eq "$$.$_tid" ) {
      return $self if ( exists $self->{JOINED} );
      sleep 0.015 until $_STAT->{$pkg}->get($mgr_id)->exists($wrk_id);
      CORE::kill($signal || 'INT', $wrk_id) if CORE::kill('ZERO', $wrk_id);
   }
   else {
      CORE::kill($signal || 'INT', $wrk_id) if CORE::kill('ZERO', $wrk_id);
   }

   $self;
}

sub list {
   _croak('Usage: MCE::Hobo->list()') if ref($_[0]);
   my $pkg = caller() eq 'MCE::Hobo' ? caller(1) : caller();

   ( exists $_LIST->{$pkg} ) ? $_LIST->{$pkg}->vals : ();
}

sub list_joinable {
   _croak('Usage: MCE::Hobo->list_joinable()') if ref($_[0]);
   my $pkg = caller; local ($!, $?, $_);

   return () unless ( exists $_LIST->{$pkg} );

   map { ( waitpid($_->{WRK_ID}, _WNOHANG) == 0 ) ? () : $_ }
         $_LIST->{$pkg}->vals;
}

sub list_running {
   _croak('Usage: MCE::Hobo->list_running()') if ref($_[0]);
   my $pkg = caller; local ($!, $?, $_);

   return () unless ( exists $_LIST->{$pkg} );

   map { ( waitpid($_->{WRK_ID}, _WNOHANG) == 0 ) ? $_ : () }
         $_LIST->{$pkg}->vals;
}

sub pending {
   _croak('Usage: MCE::Hobo->pending()') if ref($_[0]);
   my $pkg = caller;

   ( exists $_LIST->{$pkg} ) ? $_LIST->{$pkg}->len : 0;
}

sub pid {
   ref($_[0]) ? $_[0]->{WRK_ID} : $_SELF->{WRK_ID};
}

sub result {
   my ($self) = @_;
   _croak('Usage: $hobo->result()') unless ref($self);
   return $self->join if ( !exists $self->{JOINED} );

   wantarray ? @{ $self->{RESULT} } : $self->{RESULT}->[-1];
}

sub self {
   ref($_[0]) ? $_[0] : $_SELF;
}

sub waitall {
   _croak('Usage: MCE::Hobo->waitall()') if ref($_[0]);
   my $pkg = caller; local $_;

   return () if ( !exists $_LIST->{$pkg} || !$_LIST->{$pkg}->len );

   map { $_->join; $_ } $_LIST->{$pkg}->vals;
}

sub waitone {
   _croak('Usage: MCE::Hobo->waitone()') if ref($_[0]);

   my $mgr_id = "$$.$_tid";
   my $pkg    = caller() eq 'MCE::Hobo' ? caller(1) : caller();

   return undef if ( !exists $_LIST->{$pkg} || !$_LIST->{$pkg}->len );
   return undef if ( !$_DATA->{$pkg}->exists($mgr_id) );

   my ( $self, $wrk_id ); local ( $!, $? );

   while ( 1 ) {
      $wrk_id = CORE::wait();
      last if ( $self = $_LIST->{$pkg}->del($wrk_id) );
   }

   my $result = $_DATA->{$pkg}->get($mgr_id)->del($wrk_id);

   $self->{RESULT} = ( defined $result ) ? $_thaw->($result) : [];
   $self->{ERROR}  = $_STAT->{$pkg}->get($mgr_id)->del($wrk_id);
   $self->{JOINED} = 1;

   $self;
}

sub yield {
   _croak('Usage: MCE::Hobo->yield()') if ref($_[0]);
   shift if ( defined $_[0] && $_[0] eq 'MCE::Hobo' );

   ( $^O =~ /mswin|mingw|msys|cygwin/i )
      ? sleep($_[0] || 0.015)
      : sleep($_[0] || 0.0005);
}

###############################################################################
## ----------------------------------------------------------------------------
## Private methods.
##
###############################################################################

sub _croak {
   if ( $INC{'MCE.pm'} ) {
      goto &MCE::_croak;
   }
   else {
      require MCE::Shared::Base unless $INC{'MCE/Shared/Base.pm'};
      goto &MCE::Shared::Base::_croak;
   }
}

sub _dispatch {
   my ( $self, $pkg, $seed, $id, $mgr_id, $func, @args ) = @_;

   ## To avoid (Scalars leaked: N) messages; fixed in Perl 5.12.x
   @_ = ();

   local $_ = $_; my $pid = fork();

   if ( !defined $pid ) {                           # error
      return $self->_error("fork error: $!\n");
   }
   elsif ( $pid ) {                                 # parent
      $self->{WRK_ID} = $pid, $_LIST->{$pkg}->set($pid, $self);

      return $self;
   }

   my $wrk_id = $$;                                 # child

   $ENV{PERL_MCE_IPC} = 'win32' if ($^O eq 'MSWin32');
   $SIG{TERM} = $SIG{INT} = $SIG{HUP} = \&_trap;
   $SIG{QUIT} = \&_quit;

   if (UNIVERSAL::can('Prima', 'cleanup')) {
      no warnings 'redefine'; local $@; eval '*Prima::cleanup = sub {}';
   }
   {
      local $!;
      # IO::Handle->autoflush not available in older Perl.
      select(( select(*STDERR), $| = 1 )[0]) if defined(fileno *STDERR);
      select(( select(*STDOUT), $| = 1 )[0]) if defined(fileno *STDOUT);
   }

   MCE::Shared::init($id);

   $_SELF = $self, %{ $_LIST } = ();
   $_SELF->{WRK_ID} = $wrk_id;
   $_SELF->{ _pkg } = $pkg;

   ## Sets the seed of the base generator uniquely between workers.
   ## The new seed is computed using the current seed and $_wid value.
   ## One may set the seed at the application level for predictable
   ## results. Ditto for Math::Random.

   srand(abs($seed - ($id * 100000)) % 2147483560);

   if ( $INC{'Math/Random.pm'} ) {
      my $cur_seed = Math::Random::random_get_seed();

      my $new_seed = ($cur_seed < 1073741781)
         ? $cur_seed + ((abs($id) * 10000) % 1073741780)
         : $cur_seed - ((abs($id) * 10000) % 1073741780);

      Math::Random::random_set_seed($new_seed, $new_seed);
   }

   ## Run.

   local $SIG{'ALRM'} = sub { alarm 0; die "Hobo timed out\n" };

   $_STAT->{$pkg}->get($mgr_id)->set($wrk_id, '');

   my @res = eval {
      alarm( $self->{hobo_timeout} || 0 );
      no strict 'refs'; $func->(@args);
   };

   alarm 0; delete $_SELF->{_pkg};

   if ( $@ && $@ ne "Hobo exited (0)\n" ) {
      $_STAT->{$pkg}->get($mgr_id)->set($wrk_id, $@);
      warn "Hobo $wrk_id terminated abnormally: reason $@\n"
         if ( $@ ne "Hobo timed out\n" );
   }

   $_DATA->{$pkg}->get($mgr_id)->set($wrk_id, $_freeze->(\@res));

   _exit();
}

sub _error {
   local $\; print {*STDERR} $_[1];

   undef;
}

sub _exit {
   ## Hobo received a signal or exited.
   _notify() if ( exists $_SELF->{_pkg} );

   ## Check nested Hobo workers not yet joined.
   MCE::Hobo->finish('MCE') if $INC{'MCE/Hobo.pm'};

   lock $_lock if ($_tid && $^O eq 'netbsd');

   ## Exit child process.
   $SIG{__DIE__}  = sub { } unless $_tid;
   $SIG{__WARN__} = sub { };

   if ($_has_threads && $^O eq 'MSWin32') {
      threads->exit(0);
   }
   elsif ($_SELF->{posix_exit} && $^O ne 'MSWin32') {
      eval { MCE::Mutex::Channel::_destroy() };
      CORE::kill('KILL', $$);
   }

   CORE::exit(0);
}

sub _notify {
   my $mgr_id = $_SELF->{MGR_ID};
   my $wrk_id = $_SELF->{WRK_ID};
   my $pkg    = delete $_SELF->{_pkg};

   if ( $? ) {
      $_STAT->{$pkg}->get($mgr_id)->set($wrk_id, "Hobo exited ($?)\n");
      warn "Hobo $wrk_id terminated abnormally: reason Hobo exited ($?)\n\n";
   }

   $_DATA->{$pkg}->get($mgr_id)->set($wrk_id, $_freeze->([]));
}

sub _quit {
   $SIG{ $_[0] } = sub { };
   delete $_SELF->{_pkg};

   _exit();
}

sub _trap {
   $SIG{ $_[0] } = sub { };

   _exit();
}

###############################################################################
## ----------------------------------------------------------------------------
## Optimized, hash and ordhash implementations suited for MCE::Hobo.
##
###############################################################################

package MCE::Hobo::_hash;

use strict;
use warnings;

sub new    { bless {}, shift }
sub set    { $_[0]->{ $_[1] } = $_[2] }
sub get    { $_[0]->{ $_[1] } }
sub del    { delete $_[0]->{ $_[1] } }
sub exists { exists $_[0]->{ $_[1] } }
sub incr   { ++$_[0]->{ $_[1] } }

package MCE::Hobo::_ordhash;

use strict;
use warnings;

sub new {
   my $gcnt = 0; bless [ {}, [], {}, \$gcnt ], shift;
}

sub set {
   my ( $key, $data, $keys, $indx ) = ( $_[1], @{ $_[0] } );

   $data->{ $key } = $_[2], $indx->{ $key } = @{ $keys };
   push @{ $keys }, "$key";

   return;
}

sub del {
   my ( $data, $keys, $indx, $gcnt ) = @{ $_[0] };
   my $off = delete $indx->{ $_[1] };

   $keys->[ $off ] = undef;

   if ( ++${ $gcnt } > @{ $keys } * 0.667 ) {
      my $i; $i = ${ $gcnt } = 0;
      for my $k ( @{ $keys } ) {
         $keys->[ $i ] = $k, $indx->{ $k } = $i++ if ( defined $k );
      }
      splice @{ $keys }, $i;
   }

   delete $data->{ $_[1] };
}

sub clear {
   %{ $_[0]->[0] } = @{ $_[0]->[1] } = %{ $_[0]->[2] } = ();
   ${ $_[0]->[3] } = 0;

   return;
}

sub len {
   scalar keys %{ $_[0]->[0] };
}

sub vals {
   local $_; my ( $self ) = @_;

   ${ $self->[3] }
      ? @{ $self->[0] }{ grep defined($_), @{ $self->[1] } }
      : @{ $self->[0] }{ @{ $self->[1] } };
}

1;

__END__

###############################################################################
## ----------------------------------------------------------------------------
## Module usage.
##
###############################################################################

=head1 NAME

MCE::Hobo - A threads-like parallelization module

=head1 VERSION

This document describes MCE::Hobo version 1.826

=head1 SYNOPSIS

   use MCE::Hobo;

   MCE::Hobo->create( sub { print "Hello from hobo\n" } )->join();

   sub parallel {
      my ($arg1) = @_;
      print "Hello again, $arg1\n" if defined($arg1);
      print "Hello again, $_\n"; # same thing
   }

   MCE::Hobo->create( \&parallel, $_ ) for 1 .. 3;

   my @hobos    = MCE::Hobo->list();
   my @running  = MCE::Hobo->list_running();
   my @joinable = MCE::Hobo->list_joinable();
   my @count    = MCE::Hobo->pending();

   # Joining is orderly, e.g. hobo1 is joined first, hobo2, hobo3.
   $_->join() for @hobos;

   # Joining occurs immediately as hobo(s) complete execution.
   1 while MCE::Hobo->waitone();

   my $hobo = mce_async { foreach (@files) { ... } };

   $hobo->join();

   if ( my $err = $hobo->error() ) {
      warn "Hobo error: $err\n";
   }

   # Get a hobo's object
   $hobo = MCE::Hobo->self();

   # Get a hobo's ID
   $pid = MCE::Hobo->pid();  # $$
   $pid = $hobo->pid();
   $tid = MCE::Hobo->tid();  # $$  same thing
   $tid = $hobo->tid();

   # Test hobo objects
   if ( $hobo1 == $hobo2 ) {
      ...
   }

   # Give other hobos a chance to run
   MCE::Hobo->yield();
   MCE::Hobo->yield(0.05);

   # Return context, wantarray aware
   my ($value1, $value2) = $hobo->join();
   my $value = $hobo->join();

   # Check hobo's state
   if ( $hobo->is_running() ) {
      sleep 1;
   }
   if ( $hobo->is_joinable() ) {
      $hobo->join();
   }

   # Send a signal to a hobo
   $hobo->kill('SIGUSR1');

   # Exit a hobo
   MCE::Hobo->exit();

=head1 DESCRIPTION

A Hobo is a migratory worker inside the machine that carries the
asynchronous gene. Hobos are equipped with C<threads>-like capability
for running code asynchronously. Unlike threads, each hobo is a unique
process to the underlying OS. The IPC is managed by C<MCE::Shared>,
which runs on all the major platforms including Cygwin.

An exception was made on the Windows platform to spawn threads versus
children in C<MCE::Hobo> 1.807 until 1.816. For consistency, the 1.817
release reverts back to spawning children on all supported platforms.

C<MCE::Hobo> may be used as a standalone or together with C<MCE>
including running alongside C<threads>.

   use MCE::Hobo;
   use MCE::Shared;

   # synopsis: head -20 file.txt | perl script.pl

   my $ifh = MCE::Shared->handle( "<", \*STDIN  );  # shared
   my $ofh = MCE::Shared->handle( ">", \*STDOUT );
   my $ary = MCE::Shared->array();

   sub parallel_task {
      my ( $id ) = @_;

      while ( <$ifh> ) {
         printf {$ofh} "[ %4d ] %s", $., $_;

       # $ary->[ $. - 1 ] = "[ ID $id ] read line $.\n" );  # dereferencing
         $ary->set( $. - 1, "[ ID $id ] read line $.\n" );  # faster via OO
      }
   }

   my $hobo1 = MCE::Hobo->new( "parallel_task", 1 );
   my $hobo2 = MCE::Hobo->new( \&parallel_task, 2 );
   my $hobo3 = MCE::Hobo->new( sub { parallel_task(3) } );

   $_->join for MCE::Hobo->list();  # ditto: MCE::Hobo->waitall();

   # search array (total one round-trip via IPC)
   my @vals = $ary->vals( "val =~ / ID 2 /" );

   print {*STDERR} join("", @vals);

=head1 API DOCUMENTATION

=over 3

=item $hobo = MCE::Hobo->create( FUNCTION, ARGS )

=item $hobo = MCE::Hobo->new( FUNCTION, ARGS )

This will create a new hobo that will begin execution with function as the
entry point, and optionally ARGS for list of parameters. It will return the
corresponding MCE::Hobo object, or undef if hobo creation failed.

I<FUNCTION> may either be the name of a function, an anonymous subroutine, or
a code ref.

   my $hobo = MCE::Hobo->create( "func_name", ... );
       # or
   my $hobo = MCE::Hobo->create( sub { ... }, ... );
       # or
   my $hobo = MCE::Hobo->create( \&func, ... );

=item $hobo = MCE::Hobo->create( { options }, FUNCTION, ARGS )

Options may be specified via a hash structure. At this time, C<posix_exit> and
C<hobo_timeout> are the only options supported. Set C<posix_exit> to avoid all
END and destructor processing. Set C<hobo_timeout>, in number of seconds, if
you want the hobo process to terminate after some time. The default is C<0>
for no timeout.

Many modules on CPAN are not thread-safe nor safe to use with many processes.
The C<posix_exit> option must be set explicitly if your application is crashing,
due to a module with a C<DESTROY> or C<END> block not accounting for the process
ID C<$$.$tid> the object was constructed under: e.g. C<Cache::BDB>.

Constructing a Hobo inside a thread implies C<posix_exit => 1> or if present
CGI, FCGI, Curses, Gearman::Util, Gearman::XS, Mojo::IOLoop, Prima, Tk, or Wx.

   my $hobo1 = MCE::Hobo->create( { posix_exit => 1 }, sub {
      ...
   } );

   $hobo1->join;

   my $hobo2 = MCE::Hobo->create( { hobo_timeout => 3 }, sub {
      sleep 1 for ( 1 .. 9 );
   } );

   $hobo2->join;

   if ( $hobo2->error() eq "Hobo timed out\n" ) {
      ...
   }

The C<new()> method is an alias for C<create()>.

=item mce_async { BLOCK } ARGS;

=item mce_async { BLOCK };

C<mce_async> runs the block asynchronously similarly to C<MCE::Hobo->create()>.
It returns the hobo object, or undef if hobo creation failed.

   my $hobo = mce_async { foreach (@files) { ... } };

   $hobo->join();

   if ( my $err = $hobo->error() ) {
      warn("Hobo error: $err\n");
   }

=item $hobo->join()

This will wait for the corresponding hobo to complete its execution. In
non-voided context, C<join()> will return the value(s) of the entry point
function.

The context (void, scalar or list) for the return value(s) for C<join> is
determined at the time of joining and mostly C<wantarray> aware.

   my $hobo1 = MCE::Hobo->create( sub {
      my @res = qw(foo bar baz);
      return (@res);
   });

   my @res1 = $hobo1->join();  # ( foo, bar, baz )
   my $res1 = $hobo1->join();  #   baz

   my $hobo2 = MCE::Hobo->create( sub {
      return 'foo';
   });

   my @res2 = $hobo2->join();  # ( foo )
   my $res2 = $hobo2->join();  #   foo

=item $hobo1->equal( $hobo2 )

Tests if two hobo objects are the same hobo or not. Hobo comparison is based
on process IDs. This is overloaded to the more natural forms.

    if ( $hobo1 == $hobo2 ) {
        print("Hobos are the same\n");
    }
    # or
    if ( $hobo1 != $hobo2 ) {
        print("Hobos differ\n");
    }

=item $hobo->error()

Hobos are executed in an C<eval> context. This method will return C<undef>
if the hobo terminates I<normally>. Otherwise, it returns the value of
C<$@> associated with the hobo's execution status in its C<eval> context.

=item $hobo->exit()

This sends C<'SIGQUIT'> to the hobo object, notifying hobo to exit. It returns
the hobo object to allow for method chaining. It is important to join later if
not immediately to not leave a zombie or defunct process.

   $hobo->exit()->join();

   ...

   $hobo->join();  # later

=item MCE::Hobo->exit()

A hobo can be exited at any time by calling C<MCE::Hobo->exit()>.
This behaves the same as C<exit(status)> when called from the main process.

=item MCE::Hobo->finish()

This class method is called automatically by C<END>, but may be called
explicitly. Two shared objects to C<MCE::Shared> are destroyed. An error is
emitted via croak if there are active hobos not yet joined.

   MCE::Hobo->create( 'task1', $_ ) for 1 .. 4;

   $_->join for MCE::Hobo->list();

   MCE::Hobo->create( 'task2', $_ ) for 1 .. 4;

   $_->join for MCE::Hobo->list();

   MCE::Hobo->create( 'task3', $_ ) for 1 .. 4;

   $_->join for MCE::Hobo->list();

   MCE::Hobo->finish();

=item $hobo->is_running()

Returns true if a hobo is still running.

=item $hobo->is_joinable()

Returns true if the hobo has finished running and not yet joined.

=item $hobo->kill( 'SIG...' )

Sends the specified signal to the hobo. Returns the hobo object to allow for
method chaining. As with C<exit>, it is important to join eventually if not
immediately to not leave a zombie or defunct process.

   $hobo->kill('SIG...')->join();

The following is a parallel demonstration comparing C<MCE::Shared> against
C<Redis> and C<Redis::Fast> on a Fedora 23 VM. Joining begins after all
workers have been notified to quit.

   use Time::HiRes qw(time);

   use Redis;
   use Redis::Fast;

   use MCE::Hobo;
   use MCE::Shared;

   my $redis = Redis->new();
   my $rfast = Redis::Fast->new();
   my $array = MCE::Shared->array();

   sub parallel_redis {
      my ($_redis) = @_;
      my ($count, $quit, $len) = (0, 0);

      # instead, use a flag to exit loop
      $SIG{'QUIT'} = sub { $quit = 1 };

      while (1) {
         $len = $_redis->rpush('list', $count++);
         last if $quit;
      }

      $count;
   }

   sub parallel_array {
      my ($count, $quit, $len) = (0, 0);

      # do not exit from inside handler
      $SIG{'QUIT'} = sub { $quit = 1 };

      while (1) {
         $len = $array->push($count++);
         last if $quit;
      }

      $count;
   }

   sub benchmark_this {
      my ($desc, $num_hobos, $timeout, $code, @args) = @_;
      my ($start, $total) = (time(), 0);

      MCE::Hobo->new($code, @args) for 1..$num_hobos;
      sleep $timeout;

      # joining is not immediate; ok
      $_->kill('QUIT') for MCE::Hobo->list();

      # joining later; ok
      $total += $_->join() for MCE::Hobo->list();

      printf "$desc <> duration: %0.03f secs, count: $total\n",
         time() - $start;

      sleep 0.2;
   }

   benchmark_this('Redis      ', 8, 5.0, \&parallel_redis, $redis);
   benchmark_this('Redis::Fast', 8, 5.0, \&parallel_redis, $rfast);
   benchmark_this('MCE::Shared', 8, 5.0, \&parallel_array);

=item MCE::Hobo->list()

Returns a list of all hobos not yet joined.

   @hobos = MCE::Hobo->list();

=item MCE::Hobo->list_running()

Returns a list of all hobos that are still running.

   @hobos = MCE::Hobo->list_running();

=item MCE::Hobo->list_joinable()

Returns a list of all hobos that have completed running. Thus, ready to be
joined without blocking.

   @hobos = MCE::Hobo->list_joinable();

=item MCE::Hobo->pending()

Returns a count of all hobos not yet joined.

   $count = MCE::Hobo->pending();

=item $hobo->result()

Returns the result obtained by C<join>, C<waitone>, or C<waitall>. If the
process has not yet exited, waits for the corresponding hobo to complete its
execution.

   use MCE::Hobo;
   use Time::HiRes qw(sleep);

   sub task {
      my ($id) = @_;
      sleep $id * 0.333;
      return $id;
   }

   MCE::Hobo->create('task', $_) for ( reverse 1 .. 3 );

   # 1 while MCE::Hobo->waitone;

   while ( my $hobo = MCE::Hobo->waitone() ) {
      my $err = $hobo->error() // 'no error';
      my $res = $hobo->result();
      my $pid = $hobo->pid();

      print "[$pid] $err : $res\n";
   }

Like C<join> described above, the context (void, scalar or list) for the
return value(s) is determined at the time C<result> is called and mostly
C<wantarray> aware.

   my $hobo1 = MCE::Hobo->create( sub {
      my @res = qw(foo bar baz);
      return (@res);
   });

   my @res1 = $hobo1->result();  # ( foo, bar, baz )
   my $res1 = $hobo1->result();  #   baz

   my $hobo2 = MCE::Hobo->create( sub {
      return 'foo';
   });

   my @res2 = $hobo2->result();  # ( foo )
   my $res2 = $hobo2->result();  #   foo

=item MCE::Hobo->self()

Class method that allows a hobo to obtain it's own I<MCE::Hobo> object.

=item $hobo->pid()

=item $hobo->tid()

Returns the ID of the hobo.

   pid: $$  process id
   tid: $$  same thing

=item MCE::Hobo->pid()

=item MCE::Hobo->tid()

Class methods that allows a hobo to obtain its own ID.

   pid: $$  process id
   tid: $$  same thing

=item MCE::Hobo->waitone()

=item MCE::Hobo->waitall()

Meaningful for the manager process only, waits for one or all hobos to
complete execution. Afterwards, returns the corresponding hobo(s). If a
hobo does not exist, returns the C<undef> value or an empty list for
C<waitone> and C<waitall> respectively.

   use MCE::Hobo;
   use Time::HiRes qw(sleep);

   sub task {
      my $id = shift;
      sleep $id * 0.333;
      return $id;
   }

   MCE::Hobo->create('task', $_) for ( reverse 1 .. 3 );

   # join, traditional use case
   $_->join() for MCE::Hobo->list();

   # waitone, simplistic use case
   1 while MCE::Hobo->waitone();

   # waitone
   while ( my $hobo = MCE::Hobo->waitone() ) {
      my $err = $hobo->error() // 'no error';
      my $res = $hobo->result();
      my $pid = $hobo->pid();

      print "[$pid] $err : $res\n";
   }

   # waitall
   my @hobos = MCE::Hobo->waitall();

   for ( @hobos ) {
      my $err = $_->error() // 'no error';
      my $res = $_->result();
      my $pid = $_->pid();

      print "[$pid] $err : $res\n";
   }

=item MCE::Hobo->yield( floating_seconds )

Let this hobo yield CPU time to other hobos. By default, the class method calls
C<sleep(0.0005)> on UNIX and C<sleep(0.015)> on Windows including Cygwin.

   MCE::Hobo->yield();
   MCE::Hobo->yield(0.05);

=back

=head1 CROSS-PLATFORM TEMPLATE FOR BINARY EXECUTABLE

Making an executable is possible with the L<PAR::Packer> module.
On the Windows platform, threads, threads::shared, and exiting via
threads are all necessary for the binary to exit successfully.

   # https://metacpan.org/pod/PAR::Packer
   # https://metacpan.org/pod/pp
   #
   #   pp -o demo.exe demo.pl
   #   ./demo.exe

   use strict;
   use warnings;

   use if $^O eq "MSWin32", "threads";
   use if $^O eq "MSWin32", "threads::shared";

   use Time::HiRes (); # include minimum dependencies for MCE::Hobo
   use Storable ();

   use IO::FDPass ();  # optional: for MCE::Shared->condvar, handle, queue
   use Sereal ();      # optional: faster serialization, may omit Storable

   use MCE::Hobo;      # 1.808 or later on Windows
   use MCE::Shared;

   my $seq_a = MCE::Shared->sequence( 1, 30 );

   sub task {
      my ( $id ) = @_;
      while ( defined ( my $num = $seq_a->next ) ) {
         print "$id: $num\n";
      }
   }

   MCE::Hobo->new( \&task, $_ ) for 1 .. 2;
   MCE::Hobo->waitall;

   threads->exit(0) if $INC{"threads.pm"};

=head1 CREDITS

The inspiration for C<MCE::Hobo> comes from wanting C<threads>-like behavior
for processes. Both can run side-by-side including safe-use by MCE workers.
Likewise, the documentation resembles C<threads>.

The inspiration for C<waitall> and C<waitone> comes from C<Parallel::WorkUnit>.

=head1 SEE ALSO

=over 3

=item * L<forks>

=item * L<forks::BerkeleyDB>

=item * L<Parallel::ForkManager>

=item * L<Parallel::Loops>

=item * L<Parallel::Prefork>

=item * L<Parallel::WorkUnit>

=item * L<Proc::Fork>

=item * L<Thread::Tie>

=item * L<threads>

=back

=head1 INDEX

L<MCE|MCE>, L<MCE::Shared>

=head1 AUTHOR

Mario E. Roy, S<E<lt>marioeroy AT gmail DOT comE<gt>>

=cut

