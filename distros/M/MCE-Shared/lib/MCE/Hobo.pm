###############################################################################
## ----------------------------------------------------------------------------
## A threads-like parallelization module.
##
###############################################################################

use strict;
use warnings;

use 5.010001;

no warnings qw( threads recursion uninitialized once redefine );

package MCE::Hobo;

our $VERSION = '1.876';

## no critic (BuiltinFunctions::ProhibitStringyEval)
## no critic (Subroutines::ProhibitExplicitReturnUndef)
## no critic (Subroutines::ProhibitSubroutinePrototypes)
## no critic (TestingAndDebugging::ProhibitNoStrict)

use MCE::Signal ();
use MCE::Mutex ();
use MCE::Channel ();
use Time::HiRes 'sleep';

use overload (
   q(==)    => \&equal,
   q(!=)    => sub { !equal(@_) },
   fallback => 1
);

sub import {
   no strict 'refs'; no warnings 'redefine';
   *{ caller().'::mce_async' } = \&mce_async;
   return;
}

## The POSIX module has many symbols. Try not loading it simply
## to have WNOHANG. The following covers most platforms.

use constant {
   _WNOHANG => ( $INC{'POSIX.pm'} )
      ? &POSIX::WNOHANG : ( $^O eq 'solaris' ) ? 64 : 1
};

my ( $_MNGD, $_DATA, $_DELY, $_LIST ) = ( {}, {}, {}, {} );

my $_freeze = MCE::Channel::_get_freeze();
my $_thaw   = MCE::Channel::_get_thaw();

my $_is_MSWin32 = ( $^O eq 'MSWin32' ) ? 1 : 0;
my $_tid        = ( $INC{'threads.pm'} ) ? threads->tid() : 0;

sub CLONE {
   $_tid = threads->tid(), &_clear() if $INC{'threads.pm'};
}

sub _clear {
   %{ $_LIST } = ();
}

sub _max_workers {
   my ( $cpus ) = @_;
   if ( $cpus eq 'auto' ) {
      $cpus = MCE::Util::get_ncpu();
   }
   elsif ( $cpus =~ /^([0-9.]+)%$/ ) {
      my ( $percent, $ncpu ) = ( $1 / 100, MCE::Util::get_ncpu() );
      $cpus = $ncpu * $percent + 0.5;
   }
   $cpus = 1 if $cpus !~ /^[\d\.]+$/ || $cpus < 1;
   return int($cpus);
}

###############################################################################
## ----------------------------------------------------------------------------
## Init routine.
##
###############################################################################

bless my $_SELF = { MGR_ID => "$$.$_tid", WRK_ID => $$ }, __PACKAGE__;

sub init {
   shift if ( defined $_[0] && $_[0] eq __PACKAGE__ );

   # -- options ----------------------------------------------------------
   # max_workers hobo_timeout posix_exit on_start on_finish void_context
   # ---------------------------------------------------------------------

   my $pkg = "$$.$_tid.".( caller eq __PACKAGE__ ? caller(1) : caller );
   my $mngd = $_MNGD->{$pkg} = ( ref $_[0] eq 'HASH' ) ? shift : { @_ };

   @_ = ();

   $mngd->{MGR_ID} = "$$.$_tid", $mngd->{PKG} = $pkg,
   $mngd->{WRK_ID} =  $$;

   &_force_reap($pkg), $_DATA->{$pkg}->clear() if ( exists $_LIST->{$pkg} );

   if ( !exists $_LIST->{$pkg} ) {
      $MCE::_GMUTEX->lock() if ( $_tid && $MCE::_GMUTEX );
      sleep 0.015 if $_tid;

      # Start the shared-manager process if not running.
      MCE::Shared->start() if $INC{'MCE/Shared.pm'};

      my $chnl = MCE::Channel->new( impl => 'Mutex' );
      $_LIST->{ $pkg } = MCE::Hobo::_ordhash->new();
      $_DELY->{ $pkg } = MCE::Hobo::_delay->new( $chnl );
      $_DATA->{ $pkg } = MCE::Hobo::_hash->new();
      $_DATA->{"$pkg:seed"} = int(rand() * 1e9);
      $_DATA->{"$pkg:id"  } = 0;

      $MCE::_GMUTEX->unlock() if ( $_tid && $MCE::_GMUTEX );
   }

   if ( !exists $mngd->{posix_exit} ) {
      $mngd->{posix_exit} = 1 if (
         $^S || $_tid || $INC{'Mojo/IOLoop.pm'} ||
         $INC{'Coro.pm'} || $INC{'LWP/UserAgent.pm'} || $INC{'stfl.pm'} ||
         $INC{'Curses.pm'} || $INC{'CGI.pm'} || $INC{'FCGI.pm'} ||
         $INC{'Tk.pm'} || $INC{'Wx.pm'} || $INC{'Win32/GUI.pm'} ||
         $INC{'Gearman/Util.pm'} || $INC{'Gearman/XS.pm'}
      );
   }

   if ( defined $mngd->{max_workers} ) {
      $mngd->{max_workers} = _max_workers($mngd->{max_workers});
   }

   if ( $INC{'LWP/UserAgent.pm'} && !$INC{'Net/HTTP.pm'} ) {
      local $@; eval 'require Net::HTTP; require Net::HTTPS';
   }

   require POSIX
      if ( $mngd->{on_finish} && !$INC{'POSIX.pm'} && !$_is_MSWin32 );

   return;
}

###############################################################################
## ----------------------------------------------------------------------------
## 'new', 'mce_async', and 'create' for threads-like similarity.
##
###############################################################################

## 'new' and 'tid' are aliases for 'create' and 'pid' respectively.

*new = \&create, *tid = \&pid;

## Use "goto" trick to avoid pad problems from 5.8.1 (fixed in 5.8.2)
## Tip found in threads::async.

sub mce_async (&;@) {
   goto &create;
}

sub create {
   my $mngd = $_MNGD->{ "$$.$_tid.".caller() } || do {
      # construct mngd internally on first use unless defined
      init(); $_MNGD->{ "$$.$_tid.".caller() };
   };

   shift if ( $_[0] eq __PACKAGE__ );

   # ~~~ ~~~ ~~~ ~~~ ~~~ ~~~ ~~~ ~~~ ~~~ ~~~ ~~~ ~~~ ~~~ ~~~ ~~~ ~~~ ~~~ ~~~

   my $self = bless ref $_[0] eq 'HASH' ? { %{ shift() } } : { }, __PACKAGE__;

   $self->{IGNORE} = 1 if $SIG{CHLD} eq 'IGNORE';
   $self->{MGR_ID} = $mngd->{MGR_ID}, $self->{PKG} = $mngd->{PKG};
   $self->{ident } = shift if ( !ref $_[0] && ref $_[1] eq 'CODE' );

   my $func = shift; $func = caller().'::'.$func
      if ( !ref $func && length $func && index($func,':') < 0 );

   if ( !defined $func ) {
      local $\; print {*STDERR} "code function is not specified or valid\n";
      return undef;
   }

   my ( $list, $max_workers, $pkg ) = (
      $_LIST->{ $mngd->{PKG} }, $mngd->{max_workers}, $mngd->{PKG}
   );

   $_DATA->{"$pkg:id"} = 10000 if ( ( my $id = ++$_DATA->{"$pkg:id"} ) > 2e9 );

   if ( $max_workers || $self->{IGNORE} ) {
      my $wrk_id; local $!;

      # Reap completed hobo processes.
      for my $hobo ( $list->vals() ) {
         $wrk_id = $hobo->{WRK_ID};
         $list->del($wrk_id), next if $hobo->{REAPED};
         waitpid($wrk_id, _WNOHANG) or next;
         _reap_hobo($list->del($wrk_id), 0);
      }

      # Wait for a slot if saturated.
      if ( $max_workers && $list->len() >= $max_workers ) {
         my $count = $list->len() - $max_workers + 1;
         _wait_one($pkg) for 1 .. $count;
      }
   }

   # ~~~ ~~~ ~~~ ~~~ ~~~ ~~~ ~~~ ~~~ ~~~ ~~~ ~~~ ~~~ ~~~ ~~~ ~~~ ~~~ ~~~ ~~~

   $MCE::_GMUTEX->lock() if ( $_tid && $MCE::_GMUTEX );

   my @args = @_; @_ = ();  # To avoid (Scalars leaked: N) messages
   my ( $killed, $pid );

   {
      local $SIG{TERM} = local $SIG{INT} = sub { $killed = $_[0] }
         if ( !$_is_MSWin32 && $] ge '5.010001' );

      local $SIG{TTIN}, local $SIG{TTOU}, local $SIG{WINCH}
         if ( !$_is_MSWin32 );

      $pid = fork();

      if ( !defined $pid ) {                                # error
         local $\; print {*STDERR} "fork error: $!\n";
      }
      elsif ( $pid ) {                                      # parent
         $self->{WRK_ID} = $pid;
         $list->set($pid, $self);
         $mngd->{on_start}->($pid, $self->{ident}) if $mngd->{on_start};
      }
      else {                                                # child
         %{ $_LIST } = (), $_SELF = $self;

         local $SIG{TERM} = local $SIG{INT} = \&_trap,
         local $SIG{SEGV} = local $SIG{HUP} = \&_trap,
         local $SIG{QUIT} = \&_quit;
         local $SIG{CHLD};

         MCE::Shared::init() if $INC{'MCE/Shared.pm'};
         $_DATA->{ $_SELF->{PKG} }->set('S'.$$, '') unless $self->{IGNORE};
         CORE::kill($killed, $$) if $killed;

         # Sets the seed of the base generator uniquely between workers.
         # The new seed is computed using the current seed and ID value.
         # One may set the seed at the application level for predictable
         # results. Ditto for Math::Prime::Util, Math::Random, and
         # Math::Random::MT::Auto.

         srand( abs($_DATA->{"$pkg:seed"} - ($id * 100000)) % 2147483560 );

         if ( $INC{'Math/Prime/Util.pm'} ) {
            Math::Prime::Util::srand(
                abs($_DATA->{"$pkg:seed"} - ($id * 100000)) % 2147483560
            );
         }

         if ( $INC{'Math/Random.pm'} ) {
            my $cur_seed = Math::Random::random_get_seed();
            my $new_seed = ($cur_seed < 1073741781)
               ? $cur_seed + ((abs($id) * 10000) % 1073741780)
               : $cur_seed - ((abs($id) * 10000) % 1073741780);

            Math::Random::random_set_seed($new_seed, $new_seed);
         }

         if ( $INC{'Math/Random/MT/Auto.pm'} ) {
            my $cur_seed = Math::Random::MT::Auto::get_seed()->[0];
            my $new_seed = ($cur_seed < 1073741781)
               ? $cur_seed + ((abs($id) * 10000) % 1073741780)
               : $cur_seed - ((abs($id) * 10000) % 1073741780);

            Math::Random::MT::Auto::set_seed($new_seed);
         }

         _dispatch($mngd, $func, \@args);
      }
   }

   $MCE::_GMUTEX->unlock() if ( $_tid && $MCE::_GMUTEX );

   CORE::kill($killed, $$) if $killed;

   return $pid ? $self : undef;
}

###############################################################################
## ----------------------------------------------------------------------------
## Public methods.
##
###############################################################################

sub equal {
   return 0 unless ( ref $_[0] && ref $_[1] );
   $_[0]->{WRK_ID} == $_[1]->{WRK_ID} ? 1 : 0;
}

sub error {
   _croak('Usage: $hobo->error()') unless ref( my $self = $_[0] );
   $self->join() unless $self->{REAPED};
   $self->{ERROR} || undef;
}

sub exit {
   shift if ( defined $_[0] && $_[0] eq __PACKAGE__ );

   my ( $self ) = ( ref $_[0] ? shift : $_SELF );
   my ( $pkg, $wrk_id ) = ( $self->{PKG}, $self->{WRK_ID} );

   if ( $wrk_id == $$ && $self->{MGR_ID} eq "$$.$_tid" ) {
      MCE::Hobo->finish('MCE'); CORE::exit(@_);
   }
   elsif ( $wrk_id == $$ ) {
      alarm 0; my ( $exit_status, @res ) = @_; $? = $exit_status || 0;
      $_DATA->{$pkg}->set('R'.$wrk_id, @res ? $_freeze->(\@res) : '');
      die "Hobo exited ($?)\n";
      _exit($?); # not reached
   }

   return $self if $self->{REAPED};

   if ( exists $_DATA->{$pkg} ) {
      sleep 0.015 until $_DATA->{$pkg}->exists('S'.$wrk_id);
   } else {
      sleep 0.030;
   }

   if ($_is_MSWin32) {
      CORE::kill('KILL', $wrk_id) if CORE::kill('ZERO', $wrk_id);
   } else {
      CORE::kill('QUIT', $wrk_id) if CORE::kill('ZERO', $wrk_id);
   }

   $self;
}

sub finish {
   _croak('Usage: MCE::Hobo->finish()') if ref($_[0]);
   shift if ( defined $_[0] && $_[0] eq __PACKAGE__ );

   my $pkg = defined($_[0]) ? $_[0] : caller();

   if ( $pkg eq 'MCE' ) {
      for my $key ( keys %{ $_LIST } ) { MCE::Hobo->finish($key); }
   }
   elsif ( exists $_LIST->{$pkg} ) {
      return if $MCE::Signal::KILLED;

      if ( exists $_DELY->{$pkg} ) {
         &_force_reap($pkg);
         delete($_DELY->{$pkg}), delete($_DATA->{"$pkg:seed"}),
         delete($_LIST->{$pkg}), delete($_DATA->{"$pkg:id"}),
         delete($_MNGD->{$pkg}), delete($_DATA->{ $pkg });
      }
   }

   @_ = ();

   return;
}

sub is_joinable {
   _croak('Usage: $hobo->is_joinable()') unless ref( my $self = $_[0] );
   my ( $wrk_id, $pkg ) = ( $self->{WRK_ID}, $self->{PKG} );

   if ( $wrk_id == $$ ) {
      '';
   }
   elsif ( $self->{MGR_ID} eq "$$.$_tid" ) {
      return '' if $self->{REAPED};
      local $!;
      ( waitpid($wrk_id, _WNOHANG) == 0 ) ? '' : do {
         _reap_hobo($self, 0) unless $self->{REAPED};
         1;
      };
   }
   else {
      _croak('Error: $hobo->is_joinable() not called by managed process')
         if ( $self->{IGNORE} );

      return '' if $self->{REAPED};
      $_DATA->{$pkg}->exists('R'.$wrk_id) ? 1 : '';
   }
}

sub is_running {
   _croak('Usage: $hobo->is_running()') unless ref( my $self = $_[0] );
   my ( $wrk_id, $pkg ) = ( $self->{WRK_ID}, $self->{PKG} );

   if ( $wrk_id == $$ ) {
      1;
   }
   elsif ( $self->{MGR_ID} eq "$$.$_tid" ) {
      return '' if $self->{REAPED};
      local $!;
      ( waitpid($wrk_id, _WNOHANG) == 0 ) ? 1 : do {
         _reap_hobo($self, 0) unless $self->{REAPED};
         '';
      };
   }
   else {
      _croak('Error: $hobo->is_running() not called by managed process')
         if ( $self->{IGNORE} );

      return '' if $self->{REAPED};
      $_DATA->{$pkg}->exists('R'.$wrk_id) ? '' : 1;
   }
}

sub join {
   _croak('Usage: $hobo->join()') unless ref( my $self = $_[0] );
   my ( $wrk_id, $pkg ) = ( $self->{WRK_ID}, $self->{PKG} );

   if ( $self->{REAPED} ) {
      _croak('Hobo already joined') unless exists( $self->{RESULT} );
      $_LIST->{$pkg}->del($wrk_id) if ( exists $_LIST->{$pkg} );

      return ( defined wantarray )
         ? wantarray ? @{ delete $self->{RESULT} } : delete( $self->{RESULT} )->[-1]
         : ();
   }

   if ( $wrk_id == $$ ) {
      _croak('Cannot join self');
   }
   elsif ( $self->{MGR_ID} eq "$$.$_tid" ) {
      # remove from list after reaping
      if ( $_tid ) {
         local $SIG{CHLD};
         _reap_hobo($self, 1);
         $_LIST->{$pkg}->del($wrk_id);
      }
      else {
         local ($SIG{CHLD}, $!);
         waitpid($wrk_id, 0);
         _reap_hobo($self, 0);
         $_LIST->{$pkg}->del($wrk_id);
      }
   }
   else {
      _croak('Error: $hobo->join() not called by managed process')
         if ( $self->{IGNORE} );

      sleep 0.3 until ( $_DATA->{$pkg}->exists('R'.$wrk_id) );
      _reap_hobo($self, 0);
   }

   return unless ( exists $self->{RESULT} );

   ( defined wantarray )
      ? wantarray ? @{ delete $self->{RESULT} } : delete( $self->{RESULT} )->[-1]
      : ();
}

sub kill {
   _croak('Usage: $hobo->kill()') unless ref( my $self = $_[0] );
   my ( $wrk_id, $pkg, $signal ) = ( $self->{WRK_ID}, $self->{PKG}, $_[1] );

   if ( $wrk_id == $$ ) {
      CORE::kill($signal || 'INT', $$);
      return $self;
   }
   if ( $self->{MGR_ID} eq "$$.$_tid" ) {
      return $self if $self->{REAPED};
      if ( exists $_DATA->{$pkg} ) {
         sleep 0.015 until $_DATA->{$pkg}->exists('S'.$wrk_id);
      } else {
         sleep 0.030;
      }
   }

   CORE::kill($signal || 'INT', $wrk_id) if CORE::kill('ZERO', $wrk_id);

   $self;
}

sub list {
   _croak('Usage: MCE::Hobo->list()') if ref($_[0]);
   my $pkg = "$$.$_tid.".caller();

   ( exists $_LIST->{$pkg} ) ? $_LIST->{$pkg}->vals() : ();
}

sub list_pids {
   _croak('Usage: MCE::Hobo->list_pids()') if ref($_[0]);
   my $pkg = "$$.$_tid.".caller(); local $_;

   ( exists $_LIST->{$pkg} ) ? map { $_->pid } $_LIST->{$pkg}->vals() : ();
}

sub list_joinable {
   _croak('Usage: MCE::Hobo->list_joinable()') if ref($_[0]);
   my $pkg = "$$.$_tid.".caller();

   return () unless ( my $list = $_LIST->{$pkg} );
   local ($!, $?, $_);

   map {
      ( waitpid($_->{WRK_ID}, _WNOHANG) == 0 ) ? () : do {
         _reap_hobo($_, 0) unless $_->{REAPED};
         $_;
      };
   }
   $list->vals();
}

sub list_running {
   _croak('Usage: MCE::Hobo->list_running()') if ref($_[0]);
   my $pkg = "$$.$_tid.".caller();

   return () unless ( my $list = $_LIST->{$pkg} );
   local ($!, $?, $_);

   map {
      ( waitpid($_->{WRK_ID}, _WNOHANG) == 0 ) ? $_ : do {
         _reap_hobo($_, 0) unless $_->{REAPED};
         ();
      };
   }
   $list->vals();
}

sub max_workers {
   _croak('Usage: MCE::Hobo->max_workers()') if ref($_[0]);
   my $mngd = $_MNGD->{ "$$.$_tid.".caller() } || do {
      # construct mngd internally on first use unless defined
      init(); $_MNGD->{ "$$.$_tid.".caller() };
   };
   shift if ( $_[0] eq __PACKAGE__ );

   $mngd->{max_workers} = _max_workers(shift) if @_;
   $mngd->{max_workers};
}

sub pending {
   _croak('Usage: MCE::Hobo->pending()') if ref($_[0]);
   my $pkg = "$$.$_tid.".caller();

   ( exists $_LIST->{$pkg} ) ? $_LIST->{$pkg}->len() : 0;
}

sub pid {
   ref($_[0]) ? $_[0]->{WRK_ID} : $_SELF->{WRK_ID};
}

sub result {
   _croak('Usage: $hobo->result()') unless ref( my $self = $_[0] );
   return $self->join() unless $self->{REAPED};

   _croak('Hobo already joined') unless exists( $self->{RESULT} );
   wantarray ? @{ delete $self->{RESULT} } : delete( $self->{RESULT} )->[-1];
}

sub self {
   ref($_[0]) ? $_[0] : $_SELF;
}

sub wait_all {
   _croak('Usage: MCE::Hobo->wait_all()') if ref($_[0]);
   my $pkg = "$$.$_tid.".caller();

   return wantarray ? () : 0
      if ( !exists $_LIST->{$pkg} || !$_LIST->{$pkg}->len() );

   local $_; ( wantarray )
      ? map { $_->join(); $_ } $_LIST->{$pkg}->vals()
      : map { $_->join(); () } $_LIST->{$pkg}->vals();
}

*waitall = \&wait_all; # compatibility

sub wait_one {
   _croak('Usage: MCE::Hobo->wait_one()') if ref($_[0]);
   my $pkg = "$$.$_tid.".caller();

   return undef
      if ( !exists $_LIST->{$pkg} || !$_LIST->{$pkg}->len() );

   _wait_one($pkg);
}

*waitone = \&wait_one; # compatibility

sub yield {
   _croak('Usage: MCE::Hobo->yield()') if ref($_[0]);
   shift if ( defined $_[0] && $_[0] eq __PACKAGE__ );

   my $pkg = $_SELF->{PKG} || do {
      my $mngd = $_MNGD->{ "$$.$_tid.".caller() } || do {
         # construct mngd internally on first use unless defined
         init(); $_MNGD->{ "$$.$_tid.".caller() };
      };
      $mngd->{PKG};
   };

   return unless $_DELY->{$pkg};
   my $seconds = $_DELY->{$pkg}->seconds(@_);

   MCE::Util::_sleep( $seconds );
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
      $SIG{__DIE__}  = \&MCE::Signal::_die_handler;
      $SIG{__WARN__} = \&MCE::Signal::_warn_handler;

      $\ = undef; goto &Carp::croak;
   }
}

sub _dispatch {
   my ( $mngd, $func, $args ) = @_;

   $mngd->{WRK_ID} = $_SELF->{WRK_ID} = $$, $? = 0;
   $ENV{PERL_MCE_IPC} = 'win32' if $_is_MSWin32;

   {
      local $!;
      (*STDERR)->autoflush(1) if defined( fileno *STDERR );
      (*STDOUT)->autoflush(1) if defined( fileno *STDOUT );
   }

   # Run task.
   my $hobo_timeout = ( exists $_SELF->{hobo_timeout} )
      ? $_SELF->{hobo_timeout} : $mngd->{hobo_timeout};

   my $void_context = ( exists $_SELF->{void_context} )
      ? $_SELF->{void_context} : $mngd->{void_context};

   my @res; local $SIG{'ALRM'} = sub { alarm 0; die "Hobo timed out\n" };

   if ( $void_context || $_SELF->{IGNORE} ) {
      no strict 'refs';
      eval {
         alarm( $hobo_timeout || 0 );
         $func->( @{ $args } );
      };
   }
   else {
      no strict 'refs';
      @res = eval {
         alarm( $hobo_timeout || 0 );
         $func->( @{ $args } );
      };
   }

   alarm 0;

   if ( $@ ) {
      _exit($?) if ( $@ =~ /^Hobo exited \(\S+\)$/ );
      my $err = $@; $? = 1;

      if ( ! $_SELF->{IGNORE} ) {
         $_DATA->{ $_SELF->{PKG} }->set('S'.$$, $err),
         $_DATA->{ $_SELF->{PKG} }->set('R'.$$, @res ? $_freeze->(\@res) : '');
      }

      if ( $err ne "Hobo timed out" && !$mngd->{on_finish} ) {
         use bytes; warn "Hobo $$ terminated abnormally: reason $err\n";
      }
   }
   else {
      $_DATA->{ $_SELF->{PKG} }->set('R'.$$, @res ? $_freeze->(\@res) : '')
         if ( ! $_SELF->{IGNORE} );
   }

   _exit($?);
}

sub _exit {
   my ( $exit_status ) = @_;

   # Check for nested workers not yet joined.
   MCE::Hobo->finish('MCE') if ( !$_SELF->{SIGNALED} && keys %{ $_LIST } );

   # Exit hobo process.
   $SIG{__DIE__}  = sub {} unless $_tid;
   $SIG{__WARN__} = sub {};

   threads->exit($exit_status) if ( $INC{'threads.pm'} && $_is_MSWin32 );

   my $posix_exit = ( exists $_SELF->{posix_exit} )
      ? $_SELF->{posix_exit} : $_MNGD->{ $_SELF->{PKG} }{posix_exit};

   if ( ( $posix_exit || $_SELF->{SIGNALED} ) && !$_is_MSWin32 ) {
      eval { MCE::Mutex::Channel::_destroy() };
      POSIX::_exit($exit_status) if $INC{'POSIX.pm'};
      CORE::kill('KILL', $$);
   }

   CORE::exit($exit_status);
}

sub _force_reap {
   my ( $count, $pkg ) = ( 0, @_ );
   return unless ( exists $_LIST->{$pkg} && $_LIST->{$pkg}->len() );

   for my $hobo ( $_LIST->{$pkg}->vals() ) {
      next if $hobo->{IGNORE};

      if ( $hobo->is_running() ) {
         sleep(0.015), CORE::kill('KILL', $hobo->pid())
            if CORE::kill('ZERO', $hobo->pid());
         $count++;
      }
   }

   $_LIST->{$pkg}->clear();

   warn "Finished with active hobo processes [$pkg] ($count)\n"
      if ( $count && !$_is_MSWin32 );

   return;
}

sub _quit {
   return MCE::Signal::defer($_[0]) if $MCE::Signal::IPC;

   my ( $name ) = @_;
   $_SELF->{SIGNALED} = 1, $name =~ s/^SIG//;

   $SIG{$name} = sub {}, CORE::kill($name, -$$)
      if ( exists $SIG{$name} );

   _exit(0);
}

sub _reap_hobo {
   my ( $hobo, $wait_flag ) = @_;
   return unless $hobo;

   my $void_context = ( exists $hobo->{void_context} )
      ? $hobo->{void_context} : $_MNGD->{ $hobo->{PKG} }{void_context};

   local @_ = $_DATA->{ $hobo->{PKG} }->get(
      $hobo->{WRK_ID}, $wait_flag, $void_context
   );

   ( $hobo->{ERROR}, $hobo->{RESULT}, $hobo->{REAPED} ) =
      ( pop || '', length $_[0] ? $_thaw->(pop) : [], 1 );

   return if $hobo->{IGNORE};

   if ( my $on_finish = $_MNGD->{ $hobo->{PKG} }{on_finish} ) {
      my ( $exit, $err ) = ( $? || 0, $hobo->{ERROR} );
      my ( $code, $sig ) = ( $exit >> 8, $exit & 0x7f );

      if ( ( $code > 100 || $sig == 9 ) && !$err ) {
         $code = 2, $sig = 1,  $err = 'received SIGHUP'  if $code == 101;
         $code = 2, $sig = 2,  $err = 'received SIGINT'  if $code == 102;
         $code = 2, $sig = 11, $err = 'received SIGSEGV' if $code == 111;
         $code = 2, $sig = 15, $err = 'received SIGTERM' if $code == 115;
         $code = 2, $sig = 9,  $err = 'received SIGKILL' if $sig  == 9;
      }

      $on_finish->(
         $hobo->{WRK_ID}, $code, $hobo->{ident}, $sig, $err,
         @{ $hobo->{RESULT} }
      );
   }

   return;
}

sub _trap {
   return MCE::Signal::defer($_[0]) if $MCE::Signal::IPC;

   my ( $exit_status, $name ) = ( 2, @_ );
   $_SELF->{SIGNALED} = 1, $name =~ s/^SIG//;

   $SIG{$name} = sub {}, CORE::kill($name, -$$)
      if ( exists $SIG{$name} );

   if    ( $name eq 'HUP'  ) { $exit_status = 101 }
   elsif ( $name eq 'INT'  ) { $exit_status = 102 }
   elsif ( $name eq 'SEGV' ) { $exit_status = 111 }
   elsif ( $name eq 'TERM' ) { $exit_status = 115 }

   _exit($exit_status);
}

sub _wait_one {
   my ( $pkg ) = @_;
   my ( $list, $self, $wrk_id ) = ( $_LIST->{$pkg} ); local $!;

   while () {
      for my $hobo ( $list->vals() ) {
         $wrk_id = $hobo->{WRK_ID};
         return  $list->del($wrk_id) if $hobo->{REAPED};
         $self = $list->del($wrk_id), last if waitpid($wrk_id, _WNOHANG);
      }
      last if $self;
      sleep 0.030;
   }

   _reap_hobo($self, 0);

   $self;
}

###############################################################################
## ----------------------------------------------------------------------------
## Delay implementation suited for MCE::Hobo.
##
###############################################################################

package # hide from rpm
   MCE::Hobo::_delay;

sub new {
   my ( $class, $chnl, $delay ) = @_;

   if ( !defined $delay ) {
      $delay = ($^O =~ /mswin|mingw|msys|cygwin/i) ? 0.015 : 0.008;
   }

   $chnl->send(undef);

   bless [ $delay, $chnl ], $class;
}

sub seconds {
   my ( $self, $how_long ) = @_;
   my $delay = defined($how_long) ? $how_long : $self->[0];
   my $lapse = $self->[1]->recv();
   my $time  = MCE::Util::_time();

   if ( !$delay || !defined $lapse ) {
      $lapse = $time;
   }
   elsif ( $lapse + $delay - $time < 0 ) {
      $lapse += int( abs($time - $lapse) / $delay + 0.5 ) * $delay;
   }

   $self->[1]->send( $lapse += $delay );

   return $lapse - $time;
}

###############################################################################
## ----------------------------------------------------------------------------
## Hash and ordhash implementations suited for MCE::Hobo.
##
###############################################################################

package # hide from rpm
   MCE::Hobo::_hash;

use MCE::Shared ();
use Time::HiRes 'sleep';

use constant {
   _WNOHANG => ( $INC{'POSIX.pm'} )
      ? &POSIX::WNOHANG : ( $^O eq 'solaris' ) ? 64 : 1
};

sub new {
   bless \ MCE::Shared->share({ module => 'MCE::Shared::Hash' }), shift;
}

sub clear  { ${ $_[0] }->clear(); }
sub exists { ${ $_[0] }->exists($_[1]); }
sub set    { ${ $_[0] }->set($_[1], $_[2]); }

sub get {
   my ( $self, $wrk_id, $wait_flag, $void_context ) = @_;

   if ( $wait_flag ) {
      local $!;
      ( ${ $self }->exists('R'.$wrk_id) ) ? waitpid($wrk_id, 0) : do {
         while () {
            if ( ! ${ $self }->exists('R'.$wrk_id) ) {
               last if waitpid($wrk_id, _WNOHANG);
               sleep(0.030), next;
            }
            waitpid($wrk_id, 0), last;
         }
      };
   }

   ${ $self }->_get_hobo_data($wrk_id, $void_context ? 0 : 1);
}

package # hide from rpm
   MCE::Hobo::_ordhash;

sub new    { bless [ {}, [], {}, 0 ], shift; }  # data, keys, indx, gcnt
sub exists { CORE::exists $_[0]->[0]{ $_[1] }; }
sub get    { $_[0]->[0]{ $_[1] }; }
sub len    { scalar keys %{ $_[0]->[0] }; }

sub clear {
   my ( $self ) = @_;
   %{ $self->[0] } = @{ $self->[1] } = %{ $self->[2] } = (), $self->[3] = 0;

   return;
}

sub del {
   my ( $self, $key ) = @_;
   return undef unless defined( my $off = delete $self->[2]{$key} );

   # tombstone
   $self->[1][$off] = undef;

   # GC keys and refresh index
   if ( ++$self->[3] > @{ $self->[1] } * 0.667 ) {
      my ( $keys, $indx ) = ( $self->[1], $self->[2] );
      my $i; $i = $self->[3] = 0;
      for my $k ( @{ $keys } ) {
         $keys->[$i] = $k, $indx->{$k} = $i++ if defined($k);
      }
      splice @{ $keys }, $i;
   }

   delete $self->[0]{$key};
}

sub set {
   my ( $self, $key ) = @_;
   $self->[0]{$key} = $_[2], return 1 if exists($self->[0]{$key});

   $self->[2]{$key} = @{ $self->[1] }; push @{ $self->[1] }, $key;
   $self->[0]{$key} = $_[2];

   return 1;
}

sub vals {
   my ( $self ) = @_;
   $self->[3]
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

This document describes MCE::Hobo version 1.876

=head1 SYNOPSIS

 use MCE::Hobo;

 MCE::Hobo->init(
     max_workers => 'auto',   # default undef, unlimited

     # Specify a percentage. MCE::Hobo 1.874+.
     max_workers => '25%',    # 4 on HW with 16 lcores
     max_workers => '50%',    # 8 on HW with 16 lcores

     hobo_timeout => 20,      # default undef, no timeout
     posix_exit => 1,         # default undef, CORE::exit
     void_context => 1,       # default undef

     on_start => sub {
         my ( $pid, $ident ) = @_;
         ...
     },
     on_finish => sub {
         my ( $pid, $exit, $ident, $signal, $error, @ret ) = @_;
         ...
     }
 );

 MCE::Hobo->create( sub { print "Hello from hobo\n" } )->join();

 sub parallel {
     my ($arg1) = @_;
     print "Hello again, $arg1\n" if defined($arg1);
     print "Hello again, $_\n"; # same thing
 }

 MCE::Hobo->create( \&parallel, $_ ) for 1 .. 3;

 my @hobos    = MCE::Hobo->list();
 my @pids     = MCE::Hobo->list_pids();
 my @running  = MCE::Hobo->list_running();
 my @joinable = MCE::Hobo->list_joinable();
 my @count    = MCE::Hobo->pending();

 # Joining is orderly, e.g. hobo1 is joined first, hobo2, hobo3.
 $_->join() for @hobos;   # (or)
 $_->join() for @joinable;

 # Joining occurs immediately as hobo processes complete execution.
 1 while MCE::Hobo->wait_one();

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
 $pid = MCE::Hobo->tid();  # tid is an alias for pid
 $pid = $hobo->tid();

 # Test hobo objects
 if ( $hobo1 == $hobo2 ) {
     ...
 }

 # Give other workers a chance to run
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
 MCE::Hobo->exit(0);
 MCE::Hobo->exit(0, @ret);  # MCE::Hobo 1.827+

=head1 DESCRIPTION

A hobo is a migratory worker inside the machine that carries the asynchronous
gene. Hobo processes are equipped with C<threads>-like capability for running
code asynchronously. Unlike threads, each hobo is a unique process to the
underlying OS. The IPC is managed by C<MCE::Shared>, which runs on all the
major platforms including Cygwin and Strawberry Perl.

An exception was made on the Windows platform to spawn threads versus
children in C<MCE::Hobo> 1.807 through 1.816. For consistency, the 1.817
release reverts back to spawning children on all supported platforms.

C<MCE::Hobo> may be used as a standalone or together with C<MCE> including
running alongside C<threads>.

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

 $_->join for MCE::Hobo->list();  # ditto: MCE::Hobo->wait_all();

 # search array (total one round-trip via IPC)
 my @vals = $ary->vals( "val =~ / ID 2 /" );

 print {*STDERR} join("", @vals);

=head1 API DOCUMENTATION

=over 3

=item $hobo = MCE::Hobo->create( FUNCTION, ARGS )

=item $hobo = MCE::Hobo->new( FUNCTION, ARGS )

This will create a new hobo process that will begin execution with function
as the entry point, and optionally ARGS for list of parameters. It will return
the corresponding MCE::Hobo object, or undef if hobo creation failed.

I<FUNCTION> may either be the name of a function, an anonymous subroutine, or
a code ref.

 my $hobo = MCE::Hobo->create( "func_name", ... );
     # or
 my $hobo = MCE::Hobo->create( sub { ... }, ... );
     # or
 my $hobo = MCE::Hobo->create( \&func, ... );

=item $hobo = MCE::Hobo->create( { options }, FUNCTION, ARGS )

=item $hobo = MCE::Hobo->create( IDENT, FUNCTION, ARGS )

Options, excluding C<ident>, may be specified globally via the C<init> function.
Otherwise, C<ident>, C<hobo_timeout>, C<posix_exit>, and C<void_context> may
be set uniquely.

The C<ident> option, available since 1.827, is used by callback functions
C<on_start> and C<on_finish> for identifying the started and finished hobo
process respectively.

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

C<mce_async> runs the block asynchronously similarly to C<< MCE::Hobo->create() >>.
It returns the hobo object, or undef if hobo creation failed.

 my $hobo = mce_async { foreach (@files) { ... } };

 $hobo->join();

 if ( my $err = $hobo->error() ) {
     warn("Hobo error: $err\n");
 }

=item $hobo->join()

This will wait for the corresponding hobo process to complete its execution.
In non-voided context, C<join()> will return the value(s) of the entry point
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
     print("Hobo objects are the same\n");
 }
 # or
 if ( $hobo1 != $hobo2 ) {
     print("Hobo objects differ\n");
 }

=item $hobo->error()

Hobo processes are executed in an C<eval> context. This method will return
C<undef> if the hobo terminates I<normally>. Otherwise, it returns the value
of C<$@> associated with the hobo's execution status in its C<eval> context.

=item $hobo->exit()

This sends C<'SIGQUIT'> to the hobo process, notifying the hobo to exit.
It returns the hobo object to allow for method chaining. It is important to
join later if not immediately to not leave a zombie or defunct process.

 $hobo->exit()->join();
 ...

 $hobo->join();  # later

=item MCE::Hobo->exit( 0 )

=item MCE::Hobo->exit( 0, @ret )

A hobo can exit at any time by calling C<< MCE::Hobo->exit() >>.
Otherwise, the behavior is the same as C<exit(status)> when called from
the main process. Current since 1.827, the hobo process may optionally
return data, to be sent via IPC.

=item MCE::Hobo->finish()

This class method is called automatically by C<END>, but may be called
explicitly. An error is emitted via croak if there are active hobo
processes not yet joined.

 MCE::Hobo->create( 'task1', $_ ) for 1 .. 4;
 $_->join for MCE::Hobo->list();

 MCE::Hobo->create( 'task2', $_ ) for 1 .. 4;
 $_->join for MCE::Hobo->list();

 MCE::Hobo->create( 'task3', $_ ) for 1 .. 4;
 $_->join for MCE::Hobo->list();

 MCE::Hobo->finish();

=item MCE::Hobo->init( options )

The init function accepts a list of MCE::Hobo options.

 MCE::Hobo->init(
     max_workers => 'auto',   # default undef, unlimited

     # Specify a percentage. MCE::Hobo 1.874+.
     max_workers => '25%',    # 4 on HW with 16 lcores
     max_workers => '50%',    # 8 on HW with 16 lcores

     hobo_timeout => 20,      # default undef, no timeout
     posix_exit => 1,         # default undef, CORE::exit
     void_context => 1,       # default undef

     on_start => sub {
         my ( $pid, $ident ) = @_;
         ...
     },
     on_finish => sub {
         my ( $pid, $exit, $ident, $signal, $error, @ret ) = @_;
         ...
     }
 );

 # Identification given as an option or the 1st argument.
 # Current API available since 1.827.

 for my $key ( 'aa' .. 'zz' ) {
     MCE::Hobo->create( { ident => $key }, sub { ... } );
     MCE::Hobo->create( $key, sub { ... } );
 }

 MCE::Hobo->wait_all;

Set C<max_workers> if you want to limit the number of workers by waiting
automatically for an available slot. Specify a percentage or C<auto> to
obtain the number of logical cores via C<MCE::Util::get_ncpu()>.

Set C<hobo_timeout>, in number of seconds, if you want the hobo process
to terminate after some time. The default is C<0> for no timeout.

Set C<posix_exit> to avoid all END and destructor processing. Constructing
MCE::Hobo inside a thread implies 1 or if present CGI, FCGI, Coro, Curses,
Gearman::Util, Gearman::XS, LWP::UserAgent, Mojo::IOLoop, STFL, Tk, Wx,
or Win32::GUI.

Set C<void_context> to create the hobo process in void context for the
return value. Otherwise, the return context is wantarray-aware for
C<join()> and C<result()> and determined when retrieving the data.

The callback options C<on_start> and C<on_finish> are called in the parent
process after starting the worker and later when terminated. The arguments
for the subroutines were inspired by L<Parallel::ForkManager>.

The parameters for C<on_start> are the following:

 - pid of the hobo process
 - identification (ident option or 1st arg to create)

The parameters for C<on_finish> are the following:

 - pid of the hobo process
 - program exit code
 - identification (ident option or 1st arg to create)
 - exit signal id
 - error message from eval inside MCE::Hobo
 - returned data

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

     while () {
         $len = $_redis->rpush('list', $count++);
         last if $quit;
     }

     $count;
 }

 sub parallel_array {
     my ($count, $quit, $len) = (0, 0);

     # do not exit from inside handler
     $SIG{'QUIT'} = sub { $quit = 1 };

     while () {
         $len = $array->push($count++);
         last if $quit;
     }

     $count;
 }

 sub benchmark_this {
     my ($desc, $num_procs, $timeout, $code, @args) = @_;
     my ($start, $total) = (time(), 0);

     MCE::Hobo->new($code, @args) for 1..$num_procs;
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

Returns a list of all hobo objects not yet joined.

 @hobos = MCE::Hobo->list();

=item MCE::Hobo->list_pids()

Returns a list of all hobo pids not yet joined (available since 1.849).

 @pids = MCE::Hobo->list_pids();

 $SIG{INT} = $SIG{HUP} = $SIG{TERM} = sub {
     # Signal workers and the shared manager all at once
     CORE::kill('KILL', MCE::Hobo->list_pids(), MCE::Shared->pid());
     exec('reset');
 };

=item MCE::Hobo->list_running()

Returns a list of all hobo objects that are still running.

 @hobos = MCE::Hobo->list_running();

=item MCE::Hobo->list_joinable()

Returns a list of all hobo objects that have completed running.
Thus, ready to be joined without blocking.

 @hobos = MCE::Hobo->list_joinable();

=item MCE::Hobo->max_workers([ N ])

Getter and setter for max_workers. Specify a number or 'auto' to acquire the
total number of cores via MCE::Util::get_ncpu. Specify a false value to set
back to no limit.

API available since 1.835.

=item MCE::Hobo->pending()

Returns a count of all hobo objects not yet joined.

 $count = MCE::Hobo->pending();

=item $hobo->result()

Returns the result obtained by C<join>, C<wait_one>, or C<wait_all>. If the
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

 # 1 while MCE::Hobo->wait_one();

 while ( my $hobo = MCE::Hobo->wait_one() ) {
     my $err = $hobo->error() || 'no error';
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
 tid: $$  alias for pid

=item MCE::Hobo->pid()

=item MCE::Hobo->tid()

Class methods that allows a hobo to obtain its own ID.

 pid: $$  process id
 tid: $$  alias for pid

=item MCE::Hobo->wait_one()

=item MCE::Hobo->waitone()

=item MCE::Hobo->wait_all()

=item MCE::Hobo->waitall()

Meaningful for the manager process only, waits for one or all hobo processes
to complete execution. Afterwards, returns the corresponding hobo objects.
If a hobo doesn't exist, returns the C<undef> value or an empty list for
C<wait_one> and C<wait_all> respectively.

The C<waitone> and C<waitall> methods are aliases since 1.827 for
backwards compatibility.

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

 # wait_one, simplistic use case
 1 while MCE::Hobo->wait_one();

 # wait_one
 while ( my $hobo = MCE::Hobo->wait_one() ) {
     my $err = $hobo->error() || 'no error';
     my $res = $hobo->result();
     my $pid = $hobo->pid();

     print "[$pid] $err : $res\n";
 }

 # wait_all
 my @hobos = MCE::Hobo->wait_all();

 for ( @hobos ) {
     my $err = $_->error() || 'no error';
     my $res = $_->result();
     my $pid = $_->pid();

     print "[$pid] $err : $res\n";
 }

=item MCE::Hobo->yield( [ floating_seconds ] )

Prior API till 1.826.

Let this hobo yield CPU time to other workers. By default, the class method
calls C<sleep(0.008)> on UNIX and C<sleep(0.015)> on Windows including Cygwin.

 MCE::Hobo->yield();
 MCE::Hobo->yield(0.05);

 # total run time: 0.25 seconds, sleep occuring in parallel

 MCE::Hobo->create( sub { MCE::Hobo->yield(0.25) } ) for 1 .. 4;
 MCE::Hobo->wait_all();

Current API available since 1.827.

Give other workers a chance to run, optionally for given time. Yield behaves
similarly to MCE's interval option. It throttles workers from running too fast.
A demonstration is provided in the next section for fetching URLs in parallel.

The default C<floating_seconds> is 0.008 and 0.015 on UNIX and Windows,
respectively. Pass 0 if simply wanting to give other workers a chance to run.

 # total run time: 1.00 second

 MCE::Hobo->create( sub { MCE::Hobo->yield(0.25) } ) for 1 .. 4;
 MCE::Hobo->wait_all();

=back

=head1 THREADS-like DETACH CAPABILITY

Threads-like detach capability was added starting with the 1.867 release.

A threads example is shown first followed by the MCE::Hobo example. All one
needs to do is set the CHLD signal handler to IGNORE. Unfortunately, this works
on UNIX platforms only. The hobo process restores the CHLD handler to default,
so is able to deeply spin workers and reap if desired.

 use threads;

 for ( 1 .. 8 ) {
     async {
         # do something
     }->detach;
 }

 use MCE::Hobo;

 # Have the OS reap workers automatically when exiting.
 # The on_finish option is ignored if specified (no-op).
 # Ensure not inside a thread on UNIX platforms.

 $SIG{CHLD} = 'IGNORE';

 for ( 1 .. 8 ) {
     mce_async {
         # do something
     };
 }

 # Optionally, wait for any remaining workers before leaving.
 # This is necessary if workers are consuming shared objects,
 # constructed via MCE::Shared. 

 MCE::Hobo->wait_all;

The following is another way and works on Windows.
Here, the on_finish handler works as usual.

 use MCE::Hobo;

 MCE::Hobo->init(
     on_finish = sub {
         ...
     },
 );

 for ( 1 .. 8 ) {
     $_->join for MCE::Hobo->list_joinable;
     mce_async {
         # do something
     };
 }

 MCE::Hobo->wait_all;

=head1 PARALLEL::FORKMANAGER-like DEMONSTRATION

MCE::Hobo behaves similarly to threads for the most part. It also provides
L<Parallel::ForkManager>-like capabilities. The C<Parallel::ForkManager>
example is shown first followed by a version using C<MCE::Hobo>.

=over 3

=item Parallel::ForkManager

 use strict;
 use warnings;

 use Parallel::ForkManager;
 use Time::HiRes 'time';

 my $start = time;

 my $pm = Parallel::ForkManager->new(10);
 $pm->set_waitpid_blocking_sleep(0);

 $pm->run_on_finish( sub {
     my ($pid, $exit_code, $ident, $exit_signal, $core_dumped, $resp) = @_;
     print "child $pid completed: $ident => ", $resp->[0], "\n";
 });

 DATA_LOOP:
 foreach my $data ( 1..2000 ) {
     # forks and returns the pid for the child
     my $pid = $pm->start($data) and next DATA_LOOP;
     my $ret = [ $data * 2 ];

     $pm->finish(0, $ret);
 }

 $pm->wait_all_children;

 printf STDERR "duration: %0.03f seconds\n", time - $start;

=item MCE::Hobo

 use strict;
 use warnings;

 use MCE::Hobo 1.843;
 use Time::HiRes 'time';

 my $start = time;

 MCE::Hobo->init(
     max_workers => 10,
     on_finish   => sub {
         my ($pid, $exit_code, $ident, $exit_signal, $error, $resp) = @_;
         print "child $pid completed: $ident => ", $resp->[0], "\n";
     }
 );

 foreach my $data ( 1..2000 ) {
     MCE::Hobo->create( $data, sub {
         [ $data * 2 ];
     });
 }

 MCE::Hobo->wait_all;

 printf STDERR "duration: %0.03f seconds\n", time - $start;

=item Time to spin 2,000 workers and obtain results (in seconds).

Results were obtained on a Macbook Pro (2.6 GHz ~ 3.6 GHz with Turbo Boost).
Parallel::ForkManager 2.02 uses Moo. Therefore, I ran again with Moo loaded
at the top of the script.

 MCE::Hobo uses MCE::Shared to retrieve data during reaping.
 MCE::Child uses MCE::Channel, no shared-manager.

          Version  Cygwin   Windows  Linux   macOS  FreeBSD

 MCE::Child 1.843  19.099s  17.091s  0.965s  1.534s  1.229s
  MCE::Hobo 1.843  20.514s  19.594s  1.246s  1.629s  1.613s
      P::FM 1.20   19.703s  19.235s  0.875s  1.445s  1.346s

 MCE::Child 1.843  20.426s  18.417s  1.116s  1.632s  1.338s  Moo loaded
  MCE::Hobo 1.843  21.809s  20.810s  1.407s  1.759s  1.722s  Moo loaded
      P::FM 2.02   21.668s  25.927s  1.882s  2.612s  2.483s  Moo used

=item Set posix_exit to avoid all END and destructor processing.

This is helpful for reducing overhead when workers exit. Ditto if using a Perl
module not parallel safe. The option is ignored on Windows C<$^O eq 'MSWin32'>.

 MCE::Child->init( posix_exit => 1, ... );
  MCE::Hobo->init( posix_exit => 1, ... );

          Version  Cygwin   Windows  Linux   macOS  FreeBSD

 MCE::Child 1.843  19.815s  ignored  0.824s  1.284s  1.245s  Moo loaded
  MCE::Hobo 1.843  21.029s  ignored  0.953s  1.335s  1.439s  Moo loaded

=back

=head1 PARALLEL HTTP GET DEMONSTRATION USING ANYEVENT

This demonstration constructs two queues, two handles, starts the
shared-manager process if needed, and spawns four workers.
For this demonstration, am chunking 64 URLs per job. In reality,
one may run with 200 workers and chunk 300 URLs on a 24-way box.

 # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 # perl demo.pl              -- all output
 # perl demo.pl  >/dev/null  -- mngr/hobo output
 # perl demo.pl 2>/dev/null  -- show results only
 #
 # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

 use strict;
 use warnings;

 use AnyEvent;
 use AnyEvent::HTTP;
 use Time::HiRes qw( time );

 use MCE::Hobo;
 use MCE::Shared;

 # Construct two queues, input and return.

 my $que = MCE::Shared->queue();
 my $ret = MCE::Shared->queue();

 # Construct shared handles for serializing output from many workers
 # writing simultaneously. This prevents garbled output.

 mce_open my $OUT, ">>", \*STDOUT or die "open error: $!";
 mce_open my $ERR, ">>", \*STDERR or die "open error: $!";

 # Spawn workers early for minimum memory consumption.

 MCE::Hobo->create({ posix_exit => 1 }, 'task', $_) for 1 .. 4;

 # Obtain or generate input data for workers to process.

 my ( $count, @urls ) = ( 0 );

 push @urls, map { "http://127.0.0.$_/"   } 1..254;
 push @urls, map { "http://192.168.0.$_/" } 1..254; # 508 URLs total

 while ( @urls ) {
     my @chunk = splice(@urls, 0, 64);
     $que->enqueue( { ID => ++$count, INPUT => \@chunk } );
 }

 # So that workers leave the loop after consuming the queue.

 $que->end();

 # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 # Loop for the manager process. The manager may do other work if
 # need be and periodically check $ret->pending() not shown here.
 #
 # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

 my $start = time;

 printf {$ERR} "Mngr - entering loop\n";

 while ( $count ) {
     my ( $result, $failed ) = $ret->dequeue( 2 );

     # Remove ID from result, so not treated as a URL item.

     printf {$ERR} "Mngr - received job %s\n", delete $result->{ID};

     # Display the URL and the size captured.

     foreach my $url ( keys %{ $result } ) {
         printf {$OUT} "%s: %d\n", $url, length($result->{$url})
             if $result->{$url};  # url has content
     }

     # Display URLs could not reach.

     if ( @{ $failed } ) {
         foreach my $url ( @{ $failed } ) {
             print {$OUT} "Failed: $url\n";
         }
     }

     # Decrement the count.

     $count--;
 }

 MCE::Hobo->wait_all();

 printf {$ERR} "Mngr - exiting loop\n\n";
 printf {$ERR} "Duration: %0.3f seconds\n\n", time - $start;

 exit;

 # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 # Hobo processes enqueue two items ( $result and $failed ) per each
 # job for the manager process. Likewise, the manager process dequeues
 # two items above. Optionally, hobo processes may include the ID in
 # the result.
 #
 # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

 sub task {
     my ( $id ) = @_;
     printf {$ERR} "Hobo $id entering loop\n";

     while ( my $job = $que->dequeue() ) {
         my ( $result, $failed ) = ( { ID => $job->{ID} }, [ ] );

         # Walk URLs, provide a hash and array refs for data.

         printf {$ERR} "Hobo $id running  job $job->{ID}\n";
         walk( $job, $result, $failed );

         # Send results to the manager process.

         $ret->enqueue( $result, $failed );
     }

     printf {$ERR} "Hobo $id exiting loop\n";
 }

 sub walk {
     my ( $job, $result, $failed ) = @_;

     # Yielding is critical when running an event loop in parallel.
     # Not doing so means that the app may reach contention points
     # with the firewall and likely impose unnecessary hardship at
     # the OS level. The idea here is not to have multiple workers
     # initiate HTTP requests to a batch of URLs at the same time.
     # Yielding in 1.827+ behaves similarly like scatter to have
     # the hobo process run solo for a fraction of time.

     MCE::Hobo->yield( 0.03 );   # MCE::Hobo 1.827+

     my $cv = AnyEvent->condvar();

     # Populate the hash ref for the URLs it could reach.
     # Do not mix AnyEvent timeout with hobo timeout.
     # Therefore, choose event timeout when available.

     foreach my $url ( @{ $job->{INPUT} } ) {
         $cv->begin();
         http_get $url, timeout => 2, sub {
             my ( $data, $headers ) = @_;
             $result->{$url} = $data;
             $cv->end();
         };
     }

     $cv->recv();

     # Populate the array ref for URLs it could not reach.

     foreach my $url ( @{ $job->{INPUT} } ) {
         push @{ $failed }, $url unless (exists $result->{ $url });
     }

     return;
 }

 __END__

 $ perl demo.pl

 Hobo 1 entering loop
 Hobo 2 entering loop
 Hobo 3 entering loop
 Mngr - entering loop
 Hobo 2 running  job 2
 Hobo 3 running  job 3
 Hobo 1 running  job 1
 Hobo 4 entering loop
 Hobo 4 running  job 4
 Hobo 2 running  job 5
 Mngr - received job 2
 Hobo 3 running  job 6
 Mngr - received job 3
 Hobo 1 running  job 7
 Mngr - received job 1
 Hobo 4 running  job 8
 Mngr - received job 4
 http://192.168.0.1/: 3729
 Hobo 2 exiting loop
 Mngr - received job 5
 Hobo 3 exiting loop
 Mngr - received job 6
 Hobo 1 exiting loop
 Mngr - received job 7
 Hobo 4 exiting loop
 Mngr - received job 8
 Mngr - exiting loop

 Duration: 4.131 seconds

=head1 CROSS-PLATFORM TEMPLATE FOR BINARY EXECUTABLE

Making an executable is possible with the L<PAR::Packer> module.
On the Windows platform, threads, threads::shared, and exiting via
threads are necessary for the binary to exit successfully.

 # https://metacpan.org/pod/PAR::Packer
 # https://metacpan.org/pod/pp
 #
 #   pp -o demo.exe demo.pl
 #   ./demo.exe

 use strict;
 use warnings;

 use if $^O eq "MSWin32", "threads";
 use if $^O eq "MSWin32", "threads::shared";

 # Include minimum dependencies for MCE::Hobo.
 # Add other modules required by your application here.

 use Storable ();
 use Time::HiRes ();

 # use IO::FDPass ();  # optional: for condvar, handle, queue
 # use Sereal ();      # optional: for faster serialization

 use MCE::Hobo;
 use MCE::Shared;

 # For PAR to work on the Windows platform, one must include manually
 # any shared modules used by the application.

 # use MCE::Shared::Array;    # if using MCE::Shared->array
 # use MCE::Shared::Cache;    # if using MCE::Shared->cache
 # use MCE::Shared::Condvar;  # if using MCE::Shared->condvar
 # use MCE::Shared::Handle;   # if using MCE::Shared->handle, mce_open
 # use MCE::Shared::Hash;     # if using MCE::Shared->hash
 # use MCE::Shared::Minidb;   # if using MCE::Shared->minidb
 # use MCE::Shared::Ordhash;  # if using MCE::Shared->ordhash
 # use MCE::Shared::Queue;    # if using MCE::Shared->queue
 # use MCE::Shared::Scalar;   # if using MCE::Shared->scalar

 # Et cetera. Only load modules needed for your application.

 use MCE::Shared::Sequence;   # if using MCE::Shared->sequence

 my $seq = MCE::Shared->sequence( 1, 9 );

 sub task {
     my ( $id ) = @_;
     while ( defined ( my $num = $seq->next() ) ) {
         print "$id: $num\n";
         sleep 1;
     }
 }

 sub main {
     MCE::Hobo->new( \&task, $_ ) for 1 .. 3;
     MCE::Hobo->wait_all();
 }

 # Main must run inside a thread on the Windows platform or workers
 # will fail duing exiting, causing the exe to crash. The reason is
 # that PAR or a dependency isn't multi-process safe.

 ( $^O eq "MSWin32" ) ? threads->create(\&main)->join() : main();

 threads->exit(0) if $INC{"threads.pm"};

=head1 CREDITS

The inspiration for C<MCE::Hobo> comes from wanting C<threads>-like behavior
for processes. Both can run side-by-side including safe-use by MCE workers.
Likewise, the documentation resembles C<threads>.

The inspiration for C<wait_all> and C<wait_one> comes from the
C<Parallel::WorkUnit> module.

=head1 SEE ALSO

=over 3

=item * L<forks>

=item * L<forks::BerkeleyDB>

=item * L<MCE::Child>

=item * L<Parallel::ForkManager>

=item * L<Parallel::Loops>

=item * L<Parallel::Prefork>

=item * L<Parallel::WorkUnit>

=item * L<Proc::Fork>

=item * L<Thread::Tie>

=item * L<threads>

=back

=head1 INDEX

L<MCE|MCE>, L<MCE::Channel>, L<MCE::Shared>

=head1 AUTHOR

Mario E. Roy, S<E<lt>marioeroy AT gmail DOT comE<gt>>

=cut

