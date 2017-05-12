###############################################################################
## ----------------------------------------------------------------------------
## Server/Object packages for MCE::Shared.
##
###############################################################################

package MCE::Shared::Server;

use strict;
use warnings;

use 5.010001;

no warnings qw( threads recursion uninitialized numeric once );

our $VERSION = '1.826';

## no critic (BuiltinFunctions::ProhibitStringyEval)
## no critic (Subroutines::ProhibitExplicitReturnUndef)
## no critic (TestingAndDebugging::ProhibitNoStrict)
## no critic (InputOutput::ProhibitTwoArgOpen)

use Carp ();

no overloading;

my ($_has_threads, $_spawn_child, $_freeze, $_thaw);

BEGIN {
   local $@;

   if ($^O eq 'MSWin32' && !$INC{'threads.pm'}) {
      eval 'use threads; use threads::shared';
   }
   elsif ($INC{'threads.pm'} && !$INC{'threads/shared.pm'}) {
      eval 'use threads::shared';
   }

   $_has_threads = $INC{'threads.pm'} ? 1 : 0;
   $_spawn_child = $_has_threads ? 0 : 1;

   eval 'use IO::FDPass' if !$INC{'IO/FDPass.pm'} && $^O ne 'cygwin';
   eval 'PDL::no_clone_skip_warning()' if $INC{'PDL.pm'};
   eval 'use PDL::IO::Storable' if $INC{'PDL.pm'};

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

use Time::HiRes qw( sleep time );
use Scalar::Util qw( blessed weaken );
use Socket qw( SOL_SOCKET SO_RCVBUF );

use MCE::Util ();
use MCE::Signal ();
use MCE::Mutex ();
use bytes;

use constant {
   # Max data channels. This cannot be greater than 8 on MSWin32.
   DATA_CHANNELS => ($^O eq 'MSWin32') ? 8 : 12,

   SHR_M_NEW => 'M~NEW',  # New share
   SHR_M_CID => 'M~CID',  # ClientID request
   SHR_M_DEE => 'M~DEE',  # Deeply shared
   SHR_M_INC => 'M~INC',  # Increment count
   SHR_M_OBJ => 'M~OBJ',  # Object request
   SHR_M_OB0 => 'M~OB0',  # Object request - thaw'less
   SHR_M_OB1 => 'M~OB1',  # Object request - thaw'less
   SHR_M_OB2 => 'M~OB2',  # Object request - thaw'less
   SHR_M_OB3 => 'M~OB3',  # Object request - thaw'less
   SHR_M_DES => 'M~DES',  # Destroy request
   SHR_M_EXP => 'M~EXP',  # Export request
   SHR_M_INX => 'M~INX',  # Iterator next
   SHR_M_IRW => 'M~IRW',  # Iterator rewind
   SHR_M_STP => 'M~STP',  # Stop server

   SHR_O_PDL => 'O~PDL',  # PDL::ins inplace(this),what,coords
   SHR_O_FCH => 'O~FCH',  # A,H,OH,S FETCH
   SHR_O_CLR => 'O~CLR',  # A,H,OH CLEAR

   WA_ARRAY  => 1,        # Wants list
};

###############################################################################
## ----------------------------------------------------------------------------
## Private functions.
##
###############################################################################

my ($_SVR, %_all, %_obj, %_ob2, %_ob3, %_itr, %_new) = (undef);
my ($_next_id, $_is_client, $_init_pid, $_svr_pid) = (0, 1);
my $LF = "\012"; Internals::SvREADONLY($LF, 1);

my $_is_MSWin32 = ($^O eq 'MSWin32') ? 1 : 0;
my $_tid = $_has_threads ? threads->tid() : 0;
my $_oid = "$$.$_tid";

my %_iter_allow = (qw/
   MCE::Shared::Array   1
   MCE::Shared::Hash    1
   MCE::Shared::Ordhash 1
   Hash::Ordered        1
/);

sub _croak { goto &Carp::croak }
sub  CLONE { $_tid = threads->tid() if $_has_threads }

END {
   CORE::kill('KILL', $$) if ($_is_MSWin32 && $MCE::Signal::KILLED);

   _stop();
}

sub _new {
   my ($_class, $_deeply, %_hndls) = ($_[0]->{class}, $_[0]->{_DEEPLY_});

   unless ($_svr_pid) {
      # Minimum support for environments without IO::FDPass.
      # Must share Condvar and Queue before others.
      return _share(@_)
         if (!$INC{'IO/FDPass.pm'} && $_class =~
               /^MCE::Shared::(?:Condvar|Queue)$/
         );
      _start();
   }

   if ($_class =~ /^MCE::Shared::(?:Condvar|Queue)$/) {
      if (!$INC{'IO/FDPass.pm'}) {
         _croak(
            "\nSharing a $_class object while the server is running\n" .
            "requires the IO::FDPass module.\n\n"
         );
      }
      for my $_k (qw(
         _qw_sock _qr_sock _aw_sock _ar_sock _cw_sock _cr_sock _mutex
         _mutex_0 _mutex_1 _mutex_2 _mutex_3 _mutex_4 _mutex_5
      )) {
         if (defined $_[1]->{ $_k }) {
            $_hndls{ $_k } = delete $_[1]->{ $_k };
            $_[1]->{ $_k } = undef;
         }
      }
   }

   my ($_id, $_len);

   my $_chn = ($_has_threads)
      ? $_tid % $_SVR->{_data_channels} + 1
      : abs($$) % $_SVR->{_data_channels} + 1;

   my $_DAT_LOCK   = $_SVR->{'_mutex_'.$_chn};
   my $_DAT_W_SOCK = $_SVR->{_dat_w_sock}[0];
   my $_DAU_W_SOCK = $_SVR->{_dat_w_sock}[$_chn];

   my $_buf = $_freeze->(shift);
   my $_bu2 = $_freeze->([ @_ ]);

   local $\ = undef if (defined $\);
   local $/ = $LF if ($/ ne $LF);

   $_DAT_LOCK->lock();

   print({$_DAT_W_SOCK} SHR_M_NEW.$LF . $_chn.$LF),
   print({$_DAU_W_SOCK} length($_buf).$LF, $_buf, length($_bu2).$LF, $_bu2,
      (keys %_hndls ? 1 : 0).$LF);

   <$_DAU_W_SOCK>;

   undef($_buf), undef($_bu2);

   if (keys %_hndls) {
      for my $_k (qw( _qw_sock _qr_sock _aw_sock _cw_sock )) {
         if (exists $_hndls{ $_k }) {
            IO::FDPass::send( fileno $_DAU_W_SOCK, fileno $_hndls{ $_k } );
            <$_DAU_W_SOCK>;
         }
      }
   }

   chomp($_id = <$_DAU_W_SOCK>), chomp($_len = <$_DAU_W_SOCK>),
   read($_DAU_W_SOCK, $_buf, $_len);

   $_DAT_LOCK->unlock();

   if (keys %_hndls) {
      $_all{ $_id } = $_class;
      $_obj{ $_id } = \%_hndls;
   }

   unless ($_deeply) {
      # for auto-destroy
      $_new{ $_id } = $_has_threads ? $$ .'.'. $_tid : $$;
   }

   return $_thaw->($_buf);
}

sub _incr_count {
   return unless $_svr_pid;

   my $_chn = ($_has_threads)
      ? $_tid % $_SVR->{_data_channels} + 1
      : abs($$) % $_SVR->{_data_channels} + 1;

   my $_DAT_LOCK   = $_SVR->{'_mutex_'.$_chn};
   my $_DAT_W_SOCK = $_SVR->{_dat_w_sock}[0];
   my $_DAU_W_SOCK = $_SVR->{_dat_w_sock}[$_chn];

   local $\ = undef if (defined $\);
   local $/ = $LF if ($/ ne $LF);

   $_DAT_LOCK->lock();
   print({$_DAT_W_SOCK} SHR_M_INC.$LF . $_chn.$LF),
   print({$_DAU_W_SOCK} $_[0].$LF);
   <$_DAU_W_SOCK>;

   $_DAT_LOCK->unlock();

   return;
}

sub _share {
   my ($_params, $_item) = (shift, shift);
   my ($_id, $_class) = (++$_next_id, delete $_params->{'class'});

   if ($_class eq ':construct_pdl:') {
      local $@; local $SIG{__DIE__};

      $_class = 'PDL', $_item = eval q{
         use PDL; my $_func = pop @{ $_item };

         if    ($_func eq 'byte'    ) { byte     (@{ $_item }) }
         elsif ($_func eq 'short'   ) { short    (@{ $_item }) }
         elsif ($_func eq 'ushort'  ) { ushort   (@{ $_item }) }
         elsif ($_func eq 'long'    ) { long     (@{ $_item }) }
         elsif ($_func eq 'longlong') { longlong (@{ $_item }) }
         elsif ($_func eq 'float'   ) { float    (@{ $_item }) }
         elsif ($_func eq 'double'  ) { double   (@{ $_item }) }
         elsif ($_func eq 'ones'    ) { ones     (@{ $_item }) }
         elsif ($_func eq 'sequence') { sequence (@{ $_item }) }
         elsif ($_func eq 'zeroes'  ) { zeroes   (@{ $_item }) }
         elsif ($_func eq 'indx'    ) { indx     (@{ $_item }) }
         else                         { pdl      (@{ $_item }) }
      };
   }

   $_all{ $_id } = $_class; $_ob3{ "$_id:count" } = 1;

   if ($_class eq 'MCE::Shared::Handle') {
      require Symbol unless $INC{'Symbol.pm'};
      $_obj{ $_id } = Symbol::gensym();
      bless $_obj{ $_id }, 'MCE::Shared::Handle';
   }
   else {
      $_obj{ $_id } = $_item;
   }

   my $self = bless [ $_id, $_class ], 'MCE::Shared::Object';
   $_ob2{ $_id } = $_freeze->($self);

   if ( my $_code = $_obj{ $_id }->can('_shared_init') ) {
      $_code->($_obj{ $_id });
   }

   return $self;
}

sub _start {
   return if $_svr_pid;

   $_init_pid = "$$.$_tid"; local $_;

   my $_data_channels = ($_oid eq $_init_pid) ? DATA_CHANNELS : 2;
   $_SVR = { _data_channels => $_data_channels };

   MCE::Util::_sock_pair($_SVR, qw(_dat_r_sock _dat_w_sock), $_)
      for (0 .. $_data_channels);
   $_SVR->{'_mutex_'.$_} = MCE::Mutex->new( impl => 'Channel' )
      for (1 .. $_data_channels);

   setsockopt($_SVR->{_dat_r_sock}[0], SOL_SOCKET, SO_RCVBUF, 4096)
      if ($^O ne 'aix' && $^O ne 'linux');

   MCE::Shared::Object::_start();

   if ($_spawn_child) {
      $_svr_pid = fork();
      _loop() if (defined $_svr_pid && $_svr_pid == 0);
   }
   else {
      $_svr_pid = threads->create(\&_loop);
      $_svr_pid->detach(), sleep(0.005) if defined $_svr_pid;
   }

   _croak("cannot start the shared-manager process: $!")
      unless (defined $_svr_pid);

   return;
}

sub _stop {
   return unless ($_is_client && $_init_pid && $_init_pid eq "$$.$_tid");

   MCE::Hobo->finish('MCE') if $INC{'MCE/Hobo.pm'};

   local ($!, $?); %_all = (), %_obj = ();

   if (defined $_svr_pid) {
      my $_DAT_W_SOCK = $_SVR->{_dat_w_sock}[0];

      if (ref $_svr_pid) {
         local $@; eval { $_svr_pid->kill('KILL') };
      }
      else {
         local $\ = undef if (defined $\);

         ($_is_MSWin32)
            ? print {$_DAT_W_SOCK} SHR_M_STP.$LF.'0'.$LF
            : kill('KILL', $_svr_pid);

         waitpid($_svr_pid, 0);
      }

      MCE::Util::_destroy_socks($_SVR, qw( _dat_w_sock _dat_r_sock ));

      for my $_i (1 .. $_SVR->{_data_channels}) {
         delete $_SVR->{'_mutex_'.$_i};
      }

      MCE::Shared::Object::_stop();
      $_init_pid = $_svr_pid = undef;
   }

   return;
}

sub _destroy {
   my ($_lkup, $_item, $_id) = @_;

   # safety for circular references to not destroy dangerously
   return if exists $_ob3{ "$_id:count" } && --$_ob3{ "$_id:count" } > 0;

   # safety for circular references to not loop endlessly
   return if exists $_lkup->{ $_id };

   $_lkup->{ $_id } = 1;

   if (exists $_ob3{ "$_id:deeply" }) {
      for my $_oid (keys %{ $_ob3{ "$_id:deeply" } }) {
         _destroy($_lkup, $_obj{ $_oid }, $_oid);
      }
      delete $_ob3{ "$_id:deeply" };
   }
   elsif ($_all{ $_id } eq 'MCE::Shared::Scalar') {
      if (blessed($_item->get())) {
         my $_oid = $_item->get()->SHARED_ID();
         _destroy($_lkup, $_obj{ $_oid }, $_oid);
      }
      undef ${ $_obj{ $_id } };
   }
   elsif ($_all{ $_id } eq 'MCE::Shared::Handle') {
      close $_obj{ $_id } if defined(fileno($_obj{ $_id }));
   }

   weaken( delete $_obj{ $_id } ) if ( exists $_obj{ $_id } );
   weaken( delete $_itr{ $_id } ) if ( exists $_itr{ $_id } );

   delete($_ob2{ $_id }), delete($_ob3{ "$_id:count" }),
   delete($_all{ $_id }), delete($_itr{ "$_id:args"  });

   return;
}

###############################################################################
## ----------------------------------------------------------------------------
## Server loop.
##
###############################################################################

sub _exit {
   $SIG{__DIE__}  = sub { } unless $_tid;
   $SIG{__WARN__} = sub { };

   # Wait for the main thread to exit.
   if ( !$_spawn_child && (
      $_is_MSWin32 || $INC{'Prima.pm'} || $INC{'Tk.pm'} || $INC{'Wx.pm'}
   )) { sleep 3.0; }

   if ( !$_spawn_child || ($_has_threads && $_is_MSWin32) ) {
      threads->exit(0);
   }

   CORE::kill('KILL', $$) unless $_is_MSWin32;
   CORE::exit(0);
}

sub _loop {
   $_is_client = 0;

   local $\ = undef; local $/ = $LF; $| = 1;

   $SIG{QUIT} = $SIG{HUP} = $SIG{INT} = $SIG{PIPE} = $SIG{TERM} = sub { };
   $SIG{KILL} = \&_exit unless $_spawn_child;

   $SIG{__DIE__}  = \&MCE::Signal::_die_handler;
   $SIG{__WARN__} = \&MCE::Signal::_warn_handler;

   if ($_spawn_child && UNIVERSAL::can('Prima', 'cleanup')) {
      no warnings 'redefine'; local $@; eval '*Prima::cleanup = sub {}';
   }

   my ($_id, $_fn, $_wa, $_key, $_len, $_le2, $_le3, $_func);
   my ($_client_id, $_done) = (0, 0);

   my $_channels   = $_SVR->{_dat_r_sock};
   my $_DAT_R_SOCK = $_SVR->{_dat_r_sock}[0];
   my $_DAU_R_SOCK;

   my $_warn0 = sub {
      if ( $_wa ) {
         my $_buf = $_freeze->([ ]);
         print {$_DAU_R_SOCK} length($_buf).'1'.$LF, $_buf;
      }
   };
   my $_warn1 = sub {
      warn "Can't locate object method \"$_[0]\" via package \"$_[1]\"\n";
      if ( $_wa ) {
         my $_buf = $_freeze->([ ]);
         print {$_DAU_R_SOCK} length($_buf).'1'.$LF, $_buf;
      }
   };
   my $_warn2 = sub {
      warn "Can't locate object method \"$_[0]\" via package \"$_[1]\"\n";
   };

   my $_fetch = sub {
      if ( ref($_[0]) ) {
         my $_buf = ( blessed($_[0]) && $_[0]->can('SHARED_ID') )
            ? $_ob2{ $_[0]->[0] } || $_freeze->($_[0])
            : $_freeze->($_[0]);
         print {$_DAU_R_SOCK} length($_buf).'1'.$LF, $_buf;
      }
      elsif ( defined $_[0] ) {
         print {$_DAU_R_SOCK} length($_[0]).'0'.$LF, $_[0];
      }
      else {
         print {$_DAU_R_SOCK} '-1'.$LF;
      }

      return;
   };

   my $_iterator = sub {
      if (!exists $_itr{ $_id }) {

         # MCE::Shared::{ Array, Hash, Ordhash }, Hash::Ordered
         if ($_iter_allow{ $_all{ $_id } } && $_obj{ $_id }->can('keys')) {
            my @_keys = ( exists $_itr{ "$_id:args" } )
               ? $_obj{ $_id }->keys( @{ $_itr{ "$_id:args" } } )
               : $_obj{ $_id }->keys;

            $_itr{ $_id } = sub {
               my $_key = shift @_keys;
               if ( !defined $_key ) {
                  print {$_DAU_R_SOCK} '-1'.$LF;
                  return;
               }
               my $_buf = $_freeze->([ $_key, $_obj{ $_id }->get($_key) ]);
               print {$_DAU_R_SOCK} length($_buf).$LF, $_buf;
            };
         }

         # Not supported
         else {
            print {$_DAU_R_SOCK} '-1'.$LF;
            return;
         }
      }

      $_itr{ $_id }->();

      return;
   };

   # --------------------------------------------------------------------------

   my %_output_function; %_output_function = (

      SHR_M_NEW.$LF => sub {                      # New share
         my ($_buf, $_params, $_class, $_args, $_fd, $_item);

         chomp($_len = <$_DAU_R_SOCK>),
         read($_DAU_R_SOCK, $_buf, $_len);

         $_params = $_thaw->($_buf);
         $_class  = $_params->{'class'};

         if (!exists $INC{ join('/',split(/::/,$_class)).'.pm' }) {
            local $@; local $SIG{__DIE__};

            # remove tainted'ness from $_class
            ($_class) = $_class =~ /(.*)/;

            eval "use $_class ()";
         }

         chomp($_len = <$_DAU_R_SOCK>), read($_DAU_R_SOCK, $_buf, $_len),
         chomp($_len = <$_DAU_R_SOCK>), print({$_DAU_R_SOCK} $LF);

         $_args = $_thaw->($_buf); undef $_buf;

         if ($_len) {
            for my $_k (qw( _qw_sock _qr_sock _aw_sock _cw_sock )) {
               if (exists $_args->[0]->{ $_k }) {
                   delete $_args->[0]->{ $_k };
                   $_fd = IO::FDPass::recv(fileno $_DAU_R_SOCK); $_fd >= 0
                     or _croak("cannot receive file handle: $!");

                   open $_args->[0]->{ $_k }, "+<&=$_fd"
                     or _croak("cannot convert file discriptor to handle: $!");

                   print {$_DAU_R_SOCK} $LF;
               }
            }
         }

         $_item = _share($_params, @{ $_args });
         $_buf  = $_freeze->($_item);

         print {$_DAU_R_SOCK} $_item->SHARED_ID().$LF .
            length($_buf).$LF, $_buf;

         if ($_class eq 'MCE::Shared::Queue') {
            MCE::Shared::Queue::_init_mgr(
               \$_DAU_R_SOCK, \%_obj, \%_output_function, $_freeze, $_thaw
            );
         }
         elsif ($_class eq 'MCE::Shared::Handle') {
            MCE::Shared::Handle::_init_mgr(
               \$_DAU_R_SOCK, \%_obj, \%_output_function, $_thaw
            );
         }
         elsif ($_class eq 'MCE::Shared::Condvar') {
            MCE::Shared::Condvar::_init_mgr(
               \$_DAU_R_SOCK, \%_obj, \%_output_function
            );
         }

         return;
      },

      SHR_M_CID.$LF => sub {                      # ClientID request
         print {$_DAU_R_SOCK} (++$_client_id).$LF;
         $_client_id = 0 if ($_client_id > 2e9);

         return;
      },

      SHR_M_DEE.$LF => sub {                      # Deeply shared
         chomp(my $_id1 = <$_DAU_R_SOCK>),
         chomp(my $_id2 = <$_DAU_R_SOCK>);

         $_ob3{ "$_id1:deeply" }->{ $_id2 } = 1;

         return;
      },

      SHR_M_INC.$LF => sub {                      # Increment count
         chomp($_id = <$_DAU_R_SOCK>);

         $_ob3{ "$_id:count" }++;
         print {$_DAU_R_SOCK} $LF;

         return;
      },

      SHR_M_OBJ.$LF => sub {                      # Object request
         my $_buf;

         chomp($_id  = <$_DAU_R_SOCK>),
         chomp($_fn  = <$_DAU_R_SOCK>),
         chomp($_wa  = <$_DAU_R_SOCK>),
         chomp($_len = <$_DAU_R_SOCK>),

         read($_DAU_R_SOCK, $_buf, $_len);

         my $_var  = $_obj{ $_id } || do { return $_warn0->($_fn) };
         my $_code = $_var->can($_fn) || do {
            return $_warn1->($_fn, blessed($_var));
         };

         if ( $_wa == WA_ARRAY ) {
            my @_ret = $_code->($_var, @{ $_thaw->($_buf) });
            my $_buf = $_freeze->(\@_ret);
            print {$_DAU_R_SOCK} length($_buf).'1'.$LF, $_buf;
         }
         elsif ( $_wa ) {
            my $_ret = $_code->($_var, @{ $_thaw->($_buf) });
            if ( !ref($_ret) && defined($_ret) ) {
               print {$_DAU_R_SOCK} length($_ret).'0'.$LF, $_ret;
            } else {
               my $_buf = $_freeze->([ $_ret ]);
               print {$_DAU_R_SOCK} length($_buf).'1'.$LF, $_buf;
            }
         }
         else {
            $_code->($_var, @{ $_thaw->($_buf) });
         }

         return;
      },

      SHR_M_OB0.$LF => sub {                      # Object request - thaw'less
         chomp($_id = <$_DAU_R_SOCK>),
         chomp($_fn = <$_DAU_R_SOCK>),
         chomp($_wa = <$_DAU_R_SOCK>);

         my $_var  = $_obj{ $_id } || do { return $_warn0->($_fn) };
         my $_code = $_var->can($_fn) || do {
            return $_warn1->($_fn, blessed($_var));
         };

         if ( $_wa == WA_ARRAY ) {
            my @_ret = $_code->($_var);
            my $_buf = $_freeze->(\@_ret);
            print {$_DAU_R_SOCK} length($_buf).'1'.$LF, $_buf;
         }
         elsif ( $_wa ) {
            my $_ret = $_code->($_var);
            if ( !ref($_ret) && defined($_ret) ) {
               print {$_DAU_R_SOCK} length($_ret).'0'.$LF, $_ret;
            } else {
               my $_buf = $_freeze->([ $_ret ]);
               print {$_DAU_R_SOCK} length($_buf).'1'.$LF, $_buf;
            }
         }
         else {
            $_code->($_var);
         }

         return;
      },

      SHR_M_OB1.$LF => sub {                      # Object request - thaw'less
         my $_arg1;

         chomp($_id  = <$_DAU_R_SOCK>),
         chomp($_fn  = <$_DAU_R_SOCK>),
         chomp($_wa  = <$_DAU_R_SOCK>),
         chomp($_len = <$_DAU_R_SOCK>),

         read($_DAU_R_SOCK, $_arg1, $_len);

         my $_var  = $_obj{ $_id } || do { return $_warn0->($_fn) };
         my $_code = $_var->can($_fn) || do {
            return $_warn1->($_fn, blessed($_var));
         };

         if ( $_wa == WA_ARRAY ) {
            my @_ret = $_code->($_var, $_arg1);
            my $_buf = $_freeze->(\@_ret);
            print {$_DAU_R_SOCK} length($_buf).'1'.$LF, $_buf;
         }
         elsif ( $_wa ) {
            my $_ret = $_code->($_var, $_arg1);
            if ( !ref($_ret) && defined($_ret) ) {
               print {$_DAU_R_SOCK} length($_ret).'0'.$LF, $_ret;
            } else {
               my $_buf = $_freeze->([ $_ret ]);
               print {$_DAU_R_SOCK} length($_buf).'1'.$LF, $_buf;
            }
         }
         else {
            $_code->($_var, $_arg1);
         }

         return;
      },

      SHR_M_OB2.$LF => sub {                      # Object request - thaw'less
         my ($_arg1, $_arg2);

         chomp($_id  = <$_DAU_R_SOCK>),
         chomp($_fn  = <$_DAU_R_SOCK>),
         chomp($_wa  = <$_DAU_R_SOCK>),
         chomp($_len = <$_DAU_R_SOCK>),
         chomp($_le2 = <$_DAU_R_SOCK>),

         read($_DAU_R_SOCK, $_arg1, $_len),
         read($_DAU_R_SOCK, $_arg2, $_le2);

         my $_var  = $_obj{ $_id } || do { return $_warn0->($_fn) };
         my $_code = $_var->can($_fn) || do {
            return $_warn1->($_fn, blessed($_var));
         };

         if ( $_wa == WA_ARRAY ) {
            my @_ret = $_code->($_var, $_arg1, $_arg2);
            my $_buf = $_freeze->(\@_ret);
            print {$_DAU_R_SOCK} length($_buf).'1'.$LF, $_buf;
         }
         elsif ( $_wa ) {
            my $_ret = $_code->($_var, $_arg1, $_arg2);
            if ( !ref($_ret) && defined($_ret) ) {
               print {$_DAU_R_SOCK} length($_ret).'0'.$LF, $_ret;
            } else {
               my $_buf = $_freeze->([ $_ret ]);
               print {$_DAU_R_SOCK} length($_buf).'1'.$LF, $_buf;
            }
         }
         else {
            $_code->($_var, $_arg1, $_arg2);
         }

         return;
      },

      SHR_M_OB3.$LF => sub {                      # Object request - thaw'less
         my ($_arg1, $_arg2, $_arg3);

         chomp($_id  = <$_DAU_R_SOCK>),
         chomp($_fn  = <$_DAU_R_SOCK>),
         chomp($_wa  = <$_DAU_R_SOCK>),
         chomp($_len = <$_DAU_R_SOCK>),
         chomp($_le2 = <$_DAU_R_SOCK>),
         chomp($_le3 = <$_DAU_R_SOCK>),

         read($_DAU_R_SOCK, $_arg1, $_len),
         read($_DAU_R_SOCK, $_arg2, $_le2),
         read($_DAU_R_SOCK, $_arg3, $_le3);

         my $_var  = $_obj{ $_id } || do { return $_warn0->($_fn) };
         my $_code = $_var->can($_fn) || do {
            return $_warn1->($_fn, blessed($_var));
         };

         if ( $_wa == WA_ARRAY ) {
            my @_ret = $_code->($_var, $_arg1, $_arg2, $_arg3);
            my $_buf = $_freeze->(\@_ret);
            print {$_DAU_R_SOCK} length($_buf).'1'.$LF, $_buf;
         }
         elsif ( $_wa ) {
            my $_ret = $_code->($_var, $_arg1, $_arg2, $_arg3);
            if ( !ref($_ret) && defined($_ret) ) {
               print {$_DAU_R_SOCK} length($_ret).'0'.$LF, $_ret;
            } else {
               my $_buf = $_freeze->([ $_ret ]);
               print {$_DAU_R_SOCK} length($_buf).'1'.$LF, $_buf;
            }
         }
         else {
            $_code->($_var, $_arg1, $_arg2, $_arg3);
         }

         return;
      },

      SHR_M_DES.$LF => sub {                      # Destroy request
         chomp($_id = <$_DAU_R_SOCK>);

         local $SIG{__DIE__};
         local $SIG{__WARN__};

         local $@; eval {
            my $_ret = (exists $_all{ $_id }) ? '1' : '0';
            _destroy({}, $_obj{ $_id }, $_id) if $_ret;
         };

         return;
      },

      SHR_M_EXP.$LF => sub {                      # Export request
         chomp($_id  = <$_DAU_R_SOCK>),
         chomp($_len = <$_DAU_R_SOCK>);

         read($_DAU_R_SOCK, my($_keys), $_len) if $_len;

         if (exists $_obj{ $_id }) {
            my $_buf;

            # MCE::Shared::{ Array, Hash, Ordhash }, Hash::Ordered
            if ($_iter_allow{ $_all{ $_id } } && $_obj{ $_id }->can('clone')) {
               $_buf = ($_len)
                  ? $_freeze->($_obj{ $_id }->clone(@{ $_thaw->($_keys) }))
                  : $_freeze->($_obj{ $_id });
            }

            # MCE::Shared::{ Condvar, Queue }
            elsif ( $_all{ $_id } =~ /^MCE::Shared::(?:Condvar|Queue)$/ ) {
               my %_ret = %{ $_obj{ $_id } }; bless \%_ret, $_all{ $_id };
               delete @_ret{ qw(
                  _qw_sock _qr_sock _aw_sock _ar_sock _cw_sock _cr_sock _mutex
                  _mutex_0 _mutex_1 _mutex_2 _mutex_3 _mutex_4 _mutex_5
               ) };
               $_buf = $_freeze->(\%_ret);
            }

            # Other
            else {
               $_buf = $_freeze->($_obj{ $_id });
            }

            print {$_DAU_R_SOCK} length($_buf).$LF, $_buf;
            undef $_buf;
         }
         else {
            print {$_DAU_R_SOCK} '-1'.$LF;
         }

         return;
      },

      SHR_M_INX.$LF => sub {                      # Iterator next
         chomp($_id = <$_DAU_R_SOCK>);

         my $_var = $_obj{ $_id };

         if ( my $_code = $_var->can('next') ) {
            my $_buf = $_freeze->([ $_code->( $_var ) ]);
            print {$_DAU_R_SOCK} length($_buf).$LF, $_buf;
         }
         else {
            $_iterator->();
         }

         return;
      },

      SHR_M_IRW.$LF => sub {                      # Iterator rewind
         chomp($_id  = <$_DAU_R_SOCK>),
         chomp($_len = <$_DAU_R_SOCK>),

         read($_DAU_R_SOCK, my($_buf), $_len);

         my $_var  = $_obj{ $_id };
         my @_args = @{ $_thaw->($_buf) };

         if (my $_code = $_var->can('rewind')) {
            $_code->( $_var, @_args );
         }
         else {
            weaken( delete $_itr{ $_id } ) if ( exists $_itr{ $_id } );
            if ( @_args ) {
               $_itr{ "$_id:args" } = \@_args;
            } else {
               delete $_itr{ "$_id:args" };
            }
         }

         print {$_DAU_R_SOCK} $LF;

         return;
      },

      SHR_M_STP.$LF => sub {                      # Stop server
         $_done = 1;

         return;
      },

      SHR_O_PDL.$LF => sub {                      # PDL::ins inplace(this),...
         chomp($_id  = <$_DAU_R_SOCK>),
         chomp($_len = <$_DAU_R_SOCK>),

         read($_DAU_R_SOCK, my($_buf), $_len);

         if ($_all{ $_id } eq 'PDL') {
            local @_ = @{ $_thaw->($_buf) };
            if (@_ == 1) {
               # ins( inplace( $this ), $what, 0, 0 );
               ins( inplace( $_obj{ $_id } ), @_, 0, 0 );
            }
            elsif (@_ == 2) {
               # $this->slice( $arg1 ) .= $arg2;
               $_obj{ $_id }->slice( $_[0] ) .= $_[1];
            }
            elsif (@_ > 2) {
               # ins( inplace( $this ), $what, @coords );
               ins( inplace( $_obj{ $_id } ), @_ );
            }
         }

         return;
      },

      SHR_O_FCH.$LF => sub {                      # A,H,OH,S FETCH
         chomp($_id  = <$_DAU_R_SOCK>),
         chomp($_fn  = <$_DAU_R_SOCK>),
         chomp($_len = <$_DAU_R_SOCK>);

         read($_DAU_R_SOCK, $_key, $_len) if $_len;

         my $_var = $_obj{ $_id } || do {
            print {$_DAU_R_SOCK} '-1'.$LF;
            return;
         };

         if ( my $_code = $_var->can($_fn) ) {
            $_len ? $_fetch->($_code->($_var, $_key))
                  : $_fetch->($_code->($_var));
         }
         else {
            $_warn2->($_fn, blessed($_obj{ $_id }));
            print {$_DAU_R_SOCK} '-1'.$LF;
         }

         return;
      },

      SHR_O_CLR.$LF => sub {                      # A,H,OH CLEAR
         chomp($_id = <$_DAU_R_SOCK>),
         chomp($_fn = <$_DAU_R_SOCK>);

         my $_var = $_obj{ $_id } || do {
            return;
         };

         if ( my $_code = $_var->can($_fn) ) {
            if (exists $_ob3{ "$_id:deeply" }) {
               my $_keep = { $_id => 1 };
               for my $_oid (keys %{ $_ob3{ "$_id:deeply" } }) {
                  _destroy($_keep, $_obj{ $_oid }, $_oid);
               }
               delete $_ob3{ "$_id:deeply" };
            }
            $_code->($_var);
         }
         else {
            $_warn2->($_fn, blessed($_obj{ $_id }));
         }

         return;
      },

   );

   if ($INC{'MCE/Shared/Queue.pm'}) {
      MCE::Shared::Queue::_init_mgr(
         \$_DAU_R_SOCK, \%_obj, \%_output_function, $_freeze, $_thaw
      );
   }
   if ($INC{'MCE/Shared/Handle.pm'}) {
      MCE::Shared::Handle::_init_mgr(
         \$_DAU_R_SOCK, \%_obj, \%_output_function, $_thaw
      );
   }
   if ($INC{'MCE/Shared/Condvar.pm'}) {
      MCE::Shared::Condvar::_init_mgr(
         \$_DAU_R_SOCK, \%_obj, \%_output_function
      );
   }

   # --------------------------------------------------------------------------

   # Call on hash function.

   if ($_is_MSWin32) {
      # The normal loop hangs on Windows when processes/threads start/exit.
      # Using ioctl() properly, http://www.perlmonks.org/?node_id=780083

      my $_val_bytes = "\x00\x00\x00\x00";
      my $_ptr_bytes = unpack( 'I', pack('P', $_val_bytes) );
      my ($_count, $_nbytes, $_start) = (1);

      while (!$_done) {
         $_start = time;

         # MSWin32 FIONREAD
         IOCTL: ioctl($_DAT_R_SOCK, 0x4004667f, $_ptr_bytes);

         unless ($_nbytes = unpack('I', $_val_bytes)) {
            if ($_count) {
                # delay after a while to not consume a CPU core
                $_count = 0 if ++$_count % 50 == 0 && time - $_start > 0.030;
            } else {
                sleep 0.030;
            }
            goto IOCTL;
         }

         $_count = 1;

         do {
            sysread($_DAT_R_SOCK, $_func, 8);
            $_done = 1, last() unless length($_func) == 8;
            $_DAU_R_SOCK = $_channels->[ substr($_func, -2, 2, '') ];

            $_output_function{$_func}();

         } while (($_nbytes -= 8) >= 8);
      }
   }
   else {
      while (!$_done) {
         $_func = <$_DAT_R_SOCK>;
         last() unless length($_func) == 6;
         $_DAU_R_SOCK = $_channels->[ <$_DAT_R_SOCK> ];

         $_output_function{$_func}();
      }
   }

   _exit();
}

###############################################################################
## ----------------------------------------------------------------------------
## Object package.
##
###############################################################################

package MCE::Shared::Object;

use strict;
use warnings;

use 5.010001;

no warnings qw( threads recursion uninitialized numeric once );

use Time::HiRes qw( sleep );
use Scalar::Util qw( looks_like_number reftype );
use MCE::Shared::Base ();
use bytes;

use constant {
   _ID    => 0, _CLASS => 1, _DREF   => 2, _ITER => 3,  # shared object
   _UNDEF => 0, _ARRAY => 1, _SCALAR => 2,              # wantarray
};

## Below, no circular reference to original, therefore no memory leaks.

use overload (
   q("")    => \&MCE::Shared::Base::_stringify,
   q(0+)    => \&MCE::Shared::Base::_numify,
   q(@{})   => sub {
      no overloading;
      $_[0]->[_DREF] || do {
         local $@; my $c = $_[0]->[_CLASS];
         return $_[0] unless eval qq{ require $c; $c->can('TIEARRAY') };
         tie my @a, __PACKAGE__, bless([ $_[0]->[_ID] ], __PACKAGE__);
         $_[0]->[_DREF] = \@a;
      };
   },
   q(%{})   => sub {
      no overloading;
      $_[0]->[_DREF] || do {
         local $@; my $c = $_[0]->[_CLASS];
         return $_[0] unless eval qq{ require $c; $c->can('TIEHASH') };
         tie my %h, __PACKAGE__, bless([ $_[0]->[_ID] ], __PACKAGE__);
         $_[0]->[_DREF] = \%h;
      };
   },
   q(${})   => sub {
      no overloading;
      $_[0]->[_DREF] || do {
         local $@; my $c = $_[0]->[_CLASS];
         return $_[0] unless eval qq{ require $c; $c->can('TIESCALAR') };
         tie my $s, __PACKAGE__, bless([ $_[0]->[_ID] ], __PACKAGE__);
         $_[0]->[_DREF] = \$s;
      };
   },
   fallback => 1
);

no overloading;

my ($_DAT_LOCK, $_DAT_W_SOCK, $_DAU_W_SOCK, $_chn, $_dat_ex, $_dat_un);

my $_blessed = \&Scalar::Util::blessed;

BEGIN {
   $_dat_ex = sub {
      _croak(
         "\nPlease start the shared-manager process manually when ready.\n",
         "Or see section labeled \"Extra Functionality\" in MCE::Shared.\n\n"
      );
   };
}

# Hook for threads.

sub CLONE {
   $_tid = threads->tid() if $_has_threads;
   &_init($_tid)          if $_tid;
}

# Private functions.

sub DESTROY {
   return unless ($_is_client && defined $_svr_pid && defined $_[0]);

   my $_id = $_[0]->[_ID];

   if (exists $_new{ $_id }) {
      my $_pid = $_has_threads ? $$ .'.'. $_tid : $$;

      if ($_new{ $_id } eq $_pid) {
         return if $MCE::Signal::KILLED;

         delete($_all{ $_id }),
         delete($_obj{ $_id }),
         delete($_new{ $_id });

         _req2('M~DES', $_id.$LF, '');
      }
   }

   return;
}

sub _croak    { goto &MCE::Shared::Base::_croak }

sub SHARED_ID { $_[0]->[_ID] }

sub TIEARRAY  { $_[1] }
sub TIEHANDLE { $_[1] }
sub TIEHASH   { $_[1] }
sub TIESCALAR { $_[1] }

sub _reset {
   if ($INC{'MCE/Shared/Condvar.pm'}) {
      MCE::Shared::Object::_init_condvar(
         $_DAT_W_SOCK, $_DAU_W_SOCK, $_dat_ex, $_dat_un, $_chn, \%_obj,
         $_freeze, $_thaw
      );
   }
   if ($INC{'MCE/Shared/Handle.pm'}) {
      MCE::Shared::Object::_init_handle(
         $_DAT_W_SOCK, $_DAU_W_SOCK, $_dat_ex, $_dat_un, $_chn, \%_obj,
         $_freeze, $_thaw
      );
   }
   if ($INC{'MCE/Shared/Queue.pm'}) {
      MCE::Shared::Object::_init_queue(
         $_DAT_W_SOCK, $_DAU_W_SOCK, $_dat_ex, $_dat_un, $_chn, \%_obj,
         $_freeze, $_thaw
      );
   }
}

sub _start {
   $_chn        = 1;
   $_DAT_LOCK   = $_SVR->{'_mutex_'.$_chn};
   $_DAT_W_SOCK = $_SVR->{_dat_w_sock}[0];
   $_DAU_W_SOCK = $_SVR->{_dat_w_sock}[$_chn];

   # inlined for performance
   $_dat_ex = sub {
      my $_pid = $_has_threads ? $$ .'.'. $_tid : $$;
      sysread($_DAT_LOCK->{_r_sock}, my($b), 1), $_DAT_LOCK->{ $_pid } = 1
         unless $_DAT_LOCK->{ $_pid };
   };
   $_dat_un = sub {
      my $_pid = $_has_threads ? $$ .'.'. $_tid : $$;
      syswrite($_DAT_LOCK->{_w_sock}, '0'), $_DAT_LOCK->{ $_pid } = 0
         if $_DAT_LOCK->{ $_pid };
   };

   _reset();

   return;
}

sub _stop {
   $_DAT_LOCK = $_DAT_W_SOCK = $_DAU_W_SOCK = $_chn = $_dat_un = undef;

   $_dat_ex = sub {
      _croak(
         "\nPlease start the shared-manager process manually when ready.\n",
         "Or see section labeled \"Extra Functionality\" in MCE::Shared.\n\n"
      );
   };

   return;
}

sub _get_client_id {
   my $_ret;

   local $\ = undef if (defined $\);
   local $/ = $LF if ($/ ne $LF);

   $_dat_ex->();
   print {$_DAT_W_SOCK} 'M~CID'.$LF . $_chn.$LF;
   chomp($_ret = <$_DAU_W_SOCK>);
   $_dat_un->();

   return $_ret;
}

sub _init {
   return unless defined $_SVR;

   my $_id = $_[0] // &_get_client_id();
      $_id = $$ if ( $_id !~ /\d+/ );

   $_chn        = abs($_id) % $_SVR->{_data_channels} + 1;
   $_DAT_LOCK   = $_SVR->{'_mutex_'.$_chn};
   $_DAU_W_SOCK = $_SVR->{_dat_w_sock}[$_chn];

   %_new = (); _reset();

   return $_id;
}

###############################################################################
## ----------------------------------------------------------------------------
## Private routines.
##
###############################################################################

# Called by AUTOLOAD, SCALAR, STORE, and set.

sub _auto {
   my $_wa = !defined wantarray ? _UNDEF : wantarray ? _ARRAY : _SCALAR;

   local $\ = undef if (defined $\);

   if ( @_ == 2 ) {
      $_dat_ex->();
      print({$_DAT_W_SOCK} 'M~OB0'.$LF . $_chn.$LF),
      print({$_DAU_W_SOCK} $_[1]->[_ID].$LF . $_[0].$LF . $_wa.$LF);
   }
   elsif ( @_ == 3 && !ref($_[2]) && defined($_[2]) ) {
      $_dat_ex->();
      print({$_DAT_W_SOCK} 'M~OB1'.$LF . $_chn.$LF),
      print({$_DAU_W_SOCK} $_[1]->[_ID].$LF . $_[0].$LF . $_wa.$LF .
         length($_[2]).$LF, $_[2]);
   }
   elsif ( @_ == 4 && !ref($_[3]) && defined($_[3])
                   && !ref($_[2]) && defined($_[2]) ) {
      $_dat_ex->();
      print({$_DAT_W_SOCK} 'M~OB2'.$LF . $_chn.$LF),
      print({$_DAU_W_SOCK} $_[1]->[_ID].$LF . $_[0].$LF . $_wa.$LF .
         length($_[2]).$LF . length($_[3]).$LF . $_[2], $_[3]);
   }
   elsif ( @_ == 5 && !ref($_[4]) && defined($_[4])
                   && !ref($_[3]) && defined($_[3])
                   && !ref($_[2]) && defined($_[2]) ) {
      $_dat_ex->();
      print({$_DAT_W_SOCK} 'M~OB3'.$LF . $_chn.$LF),
      print({$_DAU_W_SOCK} $_[1]->[_ID].$LF . $_[0].$LF . $_wa.$LF .
         length($_[2]).$LF . length($_[3]).$LF . length($_[4]).$LF .
         $_[2] . $_[3], $_[4]);
   }
   else {
      my ( $_fn, $_id, $_tmp ) = ( shift, shift()->[_ID], $_freeze->([ @_ ]) );
      my $_buf = $_id.$LF . $_fn.$LF . $_wa.$LF . length($_tmp).$LF;

      $_dat_ex->();
      print({$_DAT_W_SOCK} 'M~OBJ'.$LF . $_chn.$LF),
      print({$_DAU_W_SOCK} $_buf, $_tmp);
   }

   if ( $_wa ) {
      local $/ = $LF if ($/ ne $LF);
      chomp(my $_len = <$_DAU_W_SOCK>);

      my $_frozen = chop($_len);
      read $_DAU_W_SOCK, my($_buf), $_len;
      $_dat_un->();

      return ( $_wa != _ARRAY )
         ? $_frozen ? $_thaw->($_buf)[0] : $_buf
         : @{ $_thaw->($_buf) };
   }

   $_dat_un->();
}

# Called by CLOSE, await, broadcast, signal, timedwait, wait, and rewind.

sub _req1 {
   local $\ = undef if (defined $\);
   local $/ = $LF if ($/ ne $LF);

   $_dat_ex->();
   print({$_DAT_W_SOCK} $_[0].$LF . $_chn.$LF),
   print({$_DAU_W_SOCK} $_[1]);

   chomp(my $_ret = <$_DAU_W_SOCK>);
   $_dat_un->();

   $_ret;
}

# Called by DESTROY, PRINT, PRINTF, STORE, destroy, ins_inplace, and set.

sub _req2 {
   local $\ = undef if (defined $\);

   $_dat_ex->();
   print({$_DAT_W_SOCK} $_[0].$LF . $_chn.$LF),
   print({$_DAU_W_SOCK} $_[1], $_[2]);
   $_dat_un->();

   1;
}

# Called by CLEAR and clear.

sub _req3 {
   my ( $_fn, $self ) = @_;
   local $\ = undef if (defined $\);
   local $/ = $LF if ($/ ne $LF);

   delete $self->[_ITER] if defined $self->[_ITER];

   $_dat_ex->();
   print({$_DAT_W_SOCK} 'O~CLR'.$LF . $_chn.$LF),
   print({$_DAU_W_SOCK} $self->[_ID].$LF . $_fn.$LF);
   $_dat_un->();

   return;
}

# Called by FETCH and get.

sub _req4 {
   local $\ = undef if (defined $\);
   local $/ = $LF if ($/ ne $LF);

   $_dat_ex->();
   print({$_DAT_W_SOCK} 'O~FCH'.$LF . $_chn.$LF),
   print({$_DAU_W_SOCK} $_[1]->[_ID].$LF . $_[0].$LF . length($_[2]).$LF, $_[2]);

   chomp(my $_len = <$_DAU_W_SOCK>);
   $_dat_un->(), return undef if ($_len < 0);

   my $_frozen = chop($_len);
   read $_DAU_W_SOCK, my($_buf), $_len;
   $_dat_un->();

   $_frozen ? $_thaw->($_buf) : $_buf;
}

###############################################################################
## ----------------------------------------------------------------------------
## Common methods.
##
###############################################################################

our $AUTOLOAD;

sub AUTOLOAD {
   # $AUTOLOAD = MCE::Shared::Object::<method_name>
   my $_fn = substr($AUTOLOAD, 21);

   # save this method for future calls
   no strict 'refs';
   *$AUTOLOAD = sub { _auto($_fn, @_) };

   goto &{ $AUTOLOAD };
}

# blessed ( )

sub blessed {
   $_[0]->[_CLASS];
}

# destroy ( { unbless => 1 } )
# destroy ( )

sub destroy {
   my $_id   = $_[0]->[_ID];
   my $_un   = (ref $_[1] eq 'HASH' && $_[1]->{'unbless'}) ? 1 : 0;
   my $_item = (defined wantarray) ? $_[0]->export({ unbless => $_un }) : undef;
   my $_pid  = $_has_threads ? $$ .'.'. $_tid : $$;

   delete($_all{ $_id }), delete($_obj{ $_id });

   if (defined $_svr_pid && exists $_new{ $_id } && $_new{ $_id } eq $_pid) {
      delete($_new{ $_id }), _req2('M~DES', $_id.$LF, '');
   }

   $_[0] = undef;
   $_item;
}

# export ( { unbless => 1 }, key [, key, ... ] )
# export ( key [, key, ... ] )
# export ( )

sub export {
   my $_ob   = shift;
   my $_id   = $_ob->[_ID];
   my $_lkup = ref($_[0]) eq 'HASH' ? shift : {};

   # safety for circular references to not loop endlessly
   return $_lkup->{ $_id } if exists $_lkup->{ $_id };

   my $_tmp   = @_ ? $_freeze->([ @_ ]) : '';
   my $_buf   = $_id.$LF . length($_tmp).$LF;
   my $_class = $_ob->[_CLASS];
   my $_item;

   if (!exists $INC{ join('/',split(/::/,$_class)).'.pm' }) {
      local $@; local $SIG{__DIE__};

      # remove tainted'ness from $_class
      ($_class) = $_class =~ /(.*)/;

      eval "use $_class ()";
   }

   {
      local $\ = undef if (defined $\);
      local $/ = $LF if ($/ ne $LF);

      $_dat_ex->();
      print({$_DAT_W_SOCK} 'M~EXP'.$LF . $_chn.$LF),
      print({$_DAU_W_SOCK} $_buf, $_tmp); undef $_buf;

      chomp(my $_len = <$_DAU_W_SOCK>);
      $_dat_un->(), return undef if ($_len < 0);

      read $_DAU_W_SOCK, $_buf, $_len;
      $_dat_un->();

      $_item = $_lkup->{ $_id } = $_thaw->($_buf);
      undef $_buf;
   }

   my $_data; local $_;

   ## no critic
   if ( $_class->isa('MCE::Shared::Array') ) {
      map { $_ = $_->export($_lkup) if $_blessed->($_) && $_->can('export')
          } @{ $_item };

      return [ @{ $_item } ] if $_lkup->{'unbless'};
   }
   elsif ( $_class->isa('MCE::Shared::Hash') ) {
      map { $_ = $_->export($_lkup) if $_blessed->($_) && $_->can('export')
          } CORE::values %{ $_item };

      return { %{ $_item } } if $_lkup->{'unbless'};
   }
   elsif ( $_class->isa('MCE::Shared::Scalar') ) {
      if ( $_blessed->(${ $_item }) && ${ $_item }->can('export') ) {
         ${ $_item } = ${ $_item }->export($_lkup);
      }
      return \do { my $o = ${ $_item } } if $_lkup->{'unbless'};
   }
   else {
      if    ( $_class->isa('MCE::Shared::Ordhash') ) { $_data = $_item->[0] }
      elsif ( $_class->isa('MCE::Shared::Cache')   ) { $_data = $_item->[0] }
      elsif ( $_class->isa('Hash::Ordered')        ) { $_data = $_item->[0] }
      elsif ( $_class->isa('Tie::IxHash')          ) { $_data = $_item->[2] }

      if ( reftype($_data) eq 'ARRAY' ) {
         map { $_ = $_->export($_lkup) if $_blessed->($_) && $_->can('export')
             } @{ $_data };
      }
      elsif ( reftype($_data) eq 'HASH' ) {
         map { $_ = $_->export($_lkup) if $_blessed->($_) && $_->can('export')
             } values %{ $_data };
      }
   }

   $_item;
}

# iterator ( index, [, index, ... ] )
# iterator ( key, [, key, ... ] )
# iterator ( "query string" )
# iterator ( )

sub iterator {
   my ( $self, @keys ) = @_;
   my $pkg = $self->blessed();

   # MCE::Shared::{ Array, Hash, Ordhash }, Hash::Ordered
   if ( $_iter_allow{ $pkg } && eval qq{ $pkg->can('keys') } ) {
      if ( ! @keys ) {
         @keys = $self->keys;
      }
      elsif ( @keys == 1 && $keys[0] =~ /^(?:key|val)[ ]+\S\S?[ ]+\S/ ) {
         @keys = $self->keys($keys[0]);
      }
      return sub {
         return unless @keys;
         my $key = shift @keys;
         return ( $key => $self->get($key) );
      };
   }

   # Not supported
   else {
      return sub { };
   }
}

# rewind ( begin, end, [ step, format ] )  # Sequence
# rewind ( index [, index, ... ] )         # Array
# rewind ( key [, key, ... ] )             # Hash, Ordhash
# rewind ( "query string" )                # Array, Hash, Ordhash
# rewind ( )

sub rewind {
   my $_id  = shift()->[_ID];
   my $_buf = $_freeze->([ @_ ]);
   _req1('M~IRW', $_id.$LF . length($_buf).$LF . $_buf);

   return;
}

# next ( )

sub next {
   local $\ = undef if (defined $\);
   local $/ = $LF if ($/ ne $LF);

   $_dat_ex->();
   print({$_DAT_W_SOCK} 'M~INX'.$LF . $_chn.$LF),
   print({$_DAU_W_SOCK} $_[0]->[_ID].$LF);

   chomp(my $_len = <$_DAU_W_SOCK>);
   $_dat_un->(), return if ($_len < 0);

   read $_DAU_W_SOCK, my($_buf), $_len;
   $_dat_un->();

   wantarray ? @{ $_thaw->($_buf) } : $_thaw->($_buf)[-1];
}

###############################################################################
## ----------------------------------------------------------------------------
## Methods optimized for:
##  MCE::Shared::{ Array, Hash, Ordhash, Scalar } and similar.
##
###############################################################################

if ($INC{'PDL.pm'}) {
   local $@; eval q{
      sub ins_inplace {
         my $_id = shift()->[_ID];
         if (@_) {
            my $_tmp = $_freeze->([ @_ ]);
            my $_buf = $_id.$LF . length($_tmp).$LF;
            _req2('O~PDL', $_buf, $_tmp);
         }
         return;
      }
   };
}

sub CLEAR { _req3('CLEAR', @_) }
sub clear { _req3('clear', @_) }
sub FETCH { _req4('FETCH', @_) }
sub get   { _req4('get'  , @_) }

sub FIRSTKEY {
   my ( $self ) = @_;
   $self->[_ITER] = [ $self->keys ];
   shift @{ $self->[_ITER] };
}

sub NEXTKEY {
   shift @{ $_[0]->[_ITER] };
}

sub SCALAR {
   _auto('SCALAR', @_);
}

sub STORE {
   if (@_ == 2 && $_blessed->($_[1]) && $_[1]->can('SHARED_ID')) {
      _req2('M~DEE', $_[0]->[_ID].$LF, $_[1]->SHARED_ID().$LF);
      delete $_new{ $_[1]->SHARED_ID() };
   }
   elsif (ref $_[2]) {
      if ($_blessed->($_[2]) && $_[2]->can('SHARED_ID')) {
         _req2('M~DEE', $_[0]->[_ID].$LF, $_[2]->SHARED_ID().$LF);
         delete $_new{ $_[2]->SHARED_ID() };
      }
      else {
         $_[2] = MCE::Shared::share({ _DEEPLY_ => 1 }, $_[2]);
         _req2('M~DEE', $_[0]->[_ID].$LF, $_[2]->SHARED_ID().$LF);
      }
   }
   _auto('STORE', @_);
   1;
}

sub set {
   if ($_blessed->($_[2]) && $_[2]->can('SHARED_ID')) {
      _req2('M~DEE', $_[0]->[_ID].$LF, $_[2]->SHARED_ID().$LF);
      delete $_new{ $_[2]->SHARED_ID() };
   }
   _auto('set', @_);
   $_[-1];
}

{
   no strict 'refs'; *{ __PACKAGE__.'::store' } = \&STORE;
}

1;

__END__

###############################################################################
## ----------------------------------------------------------------------------
## Module usage.
##
###############################################################################

=head1 NAME

MCE::Shared::Server - Server/Object packages for MCE::Shared

=head1 VERSION

This document describes MCE::Shared::Server version 1.826

=head1 DESCRIPTION

The core engine for L<MCE::Shared>. See documentation there.

=head1 INDEX

L<MCE|MCE>, L<MCE::Hobo>, L<MCE::Shared>

=head1 AUTHOR

Mario E. Roy, S<E<lt>marioeroy AT gmail DOT comE<gt>>

=cut

