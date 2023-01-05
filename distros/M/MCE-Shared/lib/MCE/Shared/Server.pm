###############################################################################
## ----------------------------------------------------------------------------
## Server/Object packages for MCE::Shared.
##
###############################################################################

use strict;
use warnings;

use 5.010001;

no warnings qw( threads recursion uninitialized numeric once );

package MCE::Shared::Server;

our $VERSION = '1.880';

## no critic (BuiltinFunctions::ProhibitStringyEval)
## no critic (Subroutines::ProhibitExplicitReturnUndef)
## no critic (TestingAndDebugging::ProhibitNoStrict)
## no critic (InputOutput::ProhibitTwoArgOpen)

use if $^O eq 'MSWin32', 'threads';
use if $^O eq 'MSWin32', 'threads::shared';

no overloading;

use Carp ();
use Storable ();

my ($_spawn_child, $_freeze, $_thaw);

BEGIN {
   local $@;

   eval 'use IO::FDPass ();'
      if ( ! $INC{'IO/FDPass.pm'} && $^O ne 'cygwin' );

   $_spawn_child = $INC{'threads.pm'} ? 0 : 1;

   if ( ! $INC{'PDL.pm'} ) {
      eval 'use Sereal::Encoder 3.015; use Sereal::Decoder 3.015;';
      if ( ! $@ ) {
         my $_encoder_ver = int( Sereal::Encoder->VERSION() );
         my $_decoder_ver = int( Sereal::Decoder->VERSION() );
         if ( $_encoder_ver - $_decoder_ver == 0 ) {
            $_freeze = \&Sereal::Encoder::encode_sereal;
            $_thaw   = \&Sereal::Decoder::decode_sereal;
         }
      }
   }

   if ( ! defined $_freeze ) {
      $_freeze = \&Storable::freeze;
      $_thaw   = \&Storable::thaw;
   }
}

sub _get_freeze { $_freeze; }
sub _get_thaw   { $_thaw;   }

use IO::Handle ();
use Scalar::Util qw( blessed looks_like_number reftype weaken );
use Socket qw( SOL_SOCKET SO_RCVBUF );
use Time::HiRes qw( alarm sleep time );

use MCE::Signal 1.863 (); # requires 1.863 minimally
use MCE::Util ();
use MCE::Mutex ();
use bytes;

## The POSIX module has many symbols. Try not loading it simply
## to have WNOHANG. The following covers most platforms.

use constant {
   _WNOHANG => ( $INC{'POSIX.pm'} )
      ? &POSIX::WNOHANG : ( $^O eq 'solaris' ) ? 64 : 1
};

use constant {
   # Max data channels. This cannot be greater than 8 on MSWin32.
   DATA_CHANNELS => 8,

   SHR_M_NEW => 'M~NEW',  # New share
   SHR_M_CID => 'M~CID',  # ClientID request
   SHR_M_DEE => 'M~DEE',  # Deeply shared
   SHR_M_INC => 'M~INC',  # Increment count
   SHR_M_OBJ => 'M~OBJ',  # Object request
   SHR_M_OB0 => 'M~OB0',  # Object request - thaw'less
   SHR_M_DES => 'M~DES',  # Destroy request
   SHR_M_EXP => 'M~EXP',  # Export request
   SHR_M_INX => 'M~INX',  # Iterator next
   SHR_M_IRW => 'M~IRW',  # Iterator rewind
   SHR_M_STP => 'M~STP',  # Exit loop

   SHR_O_PDL => 'O~PDL',  # PDL::ins inplace(this),what,coords
   SHR_O_DAT => 'O~DAT',  # Get MCE::Hobo data
   SHR_O_CLR => 'O~CLR',  # Clear
   SHR_O_FCH => 'O~FCH',  # Fetch
   SHR_O_SZE => 'O~SZE',  # Size

   WA_ARRAY  => 1,        # Wants list
};

###############################################################################
## ----------------------------------------------------------------------------
## Private functions.
##
###############################################################################

my ($_SVR, $_stopped, %_all, %_obj, %_ob2, %_ob3, %_itr, %_new) = (undef);
my ($_next_id, $_is_client, $_init_pid, $_svr_pid) = (0, 1);
my $LF = "\012"; Internals::SvREADONLY($LF, 1);
my %_export_nul;

my @_db_modules = qw(
   AnyDBM_File DB_File GDBM_File NDBM_File ODBM_File SDBM_File
   BerkeleyDB::Btree BerkeleyDB::Hash BerkeleyDB::Queue
   BerkeleyDB::Recno CDB_File KyotoCabinet::DB SQLite_File
   TokyoCabinet::ADB TokyoCabinet::BDB TokyoCabinet::HDB
   Tie::Array::DBD Tie::Hash::DBD
);

my $_is_MSWin32 = ( $^O eq 'MSWin32') ? 1 : 0;
my $_tid = $INC{'threads.pm'} ? threads->tid() : 0;
my $_oid = "$$.$_tid";

sub _croak {
   Carp::carp($_[0]);
   MCE::Signal::stop_and_exit('INT');
}
sub CLONE {
   $_tid = threads->tid() if $INC{'threads.pm'};
}

END {
   CORE::kill('KILL', $$)
      if ($_is_MSWin32 && $MCE::Signal::KILLED);
   &_stop()
      if ($_init_pid && $_init_pid eq "$$.$_tid" && $_is_client);
}

sub _new {
   my ($_class, $_deeply, %_hndls) = ($_[0]->{class}, $_[0]->{_DEEPLY_});
   my $_has_fh = ($_class =~ /^MCE::Shared::(?:Condvar|Queue)$/);

   if (!$_svr_pid) {
      # Minimum support on platforms without IO::FDPass (not installed).
      # Condvar and Queue must be shared first before others.
      $_export_nul{ $_class } = undef, return _share(@_)
         if $_has_fh && !$INC{'IO/FDPass.pm'};

      _start();
   }

   if ($_has_fh) {
      _croak("Sharing module '$_class' while the server is running\n".
             "requires the 'IO::FDPass' module, missing in Perl")
         if !$INC{'IO/FDPass.pm'};

      for my $_k (qw(
         _qw_sock _qr_sock _aw_sock _ar_sock _cw_sock _cr_sock
         _mutex_0 _mutex_1 _mutex_2 _mutex_3 _mutex_4 _mutex_5
      )) {
         if ( defined $_[1]->{ $_k } ) {
            $_hndls{ $_k } = delete $_[1]->{ $_k };
            $_[1]->{ $_k } = undef;
         }
      }
   }

   my $_chn        = $_SVR->{_data_channels} + 1;
   my $_DAT_LOCK   = $_SVR->{'_mutex_'.$_chn};
   my $_DAT_W_SOCK = $_SVR->{_dat_w_sock}[0];
   my $_DAU_W_SOCK = $_SVR->{_dat_w_sock}[$_chn];

   ##
   # Sereal cannot encode $DB_RECNO. Therefore, must encode using Storable.
   # Error: DB_File::RECNOINFO does not define the method FIRSTKEY
   #
   # my $ob = tie my @db, 'MCE::Shared', { module => 'DB_File' }, $file,
   #    O_RDWR|O_CREAT, 0640, $DB_RECNO or die "open error '$file': $!";
   ##

   my $_buf = Storable::freeze(shift);
   my $_bu2 = Storable::freeze([ @_ ]);

   local $\ = undef if (defined $\);
   local $/ = $LF if ($/ ne $LF);

   $_is_MSWin32 ? CORE::lock $_DAT_LOCK : $_DAT_LOCK->lock();

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

   chomp(my $_id  = <$_DAU_W_SOCK>),
   chomp(my $_len = <$_DAU_W_SOCK>);

   read($_DAU_W_SOCK, $_buf, $_len) if $_len;

   $_DAT_LOCK->unlock() if !$_is_MSWin32;

   $! = $_id, return '' unless $_len;

   if (keys %_hndls) {
      $_all{ $_id } = $_class;
      $_obj{ $_id } = \%_hndls;
   }

   if (!$_deeply) {
      # for auto-destroy
      $_new{ $_id } = $_tid ? $$ .'.'. $_tid : $$;
   }

   return $_thaw->($_buf);
}

sub _incr_count {
   return unless $_svr_pid;

   my $_chn        = $_SVR->{_data_channels} + 1;
   my $_DAT_LOCK   = $_SVR->{'_mutex_'.$_chn};
   my $_DAT_W_SOCK = $_SVR->{_dat_w_sock}[0];
   my $_DAU_W_SOCK = $_SVR->{_dat_w_sock}[$_chn];

   local $\ = undef if (defined $\);
   local $/ = $LF if ($/ ne $LF);
   local $MCE::Signal::SIG;

   {
      local $MCE::Signal::IPC = 1;
      $_is_MSWin32 ? CORE::lock $_DAT_LOCK : $_DAT_LOCK->lock();

      print({$_DAT_W_SOCK} SHR_M_INC.$LF . $_chn.$LF),
      print({$_DAU_W_SOCK} $_[0].$LF);
      <$_DAU_W_SOCK>;

      $_DAT_LOCK->unlock() if !$_is_MSWin32;
   }

   CORE::kill($MCE::Signal::SIG, $$) if $MCE::Signal::SIG;

   return;
}

sub _share {
   my ($_params, $_item) = (shift, shift);
   my $_class = delete $_params->{'class'};
   my $_id = ++$_next_id;

   if ($_class eq ':construct_module:') {
      my ($_module, $_fcn) = ($_params->{module}, pop @{ $_item });
      my $_has_args = @{ $_item } ? 1 : 0; local $@;

      ($_module) = $_module =~ /(.*)/; # remove tainted'ness
      ($_fcn   ) = $_fcn    =~ /(.*)/;

      MCE::Shared::_use( $_class = $_module ) or _croak("$@\n");

      _croak("Can't locate object method \"$_fcn\" via package \"$_module\"")
         unless eval qq{ $_module->can('$_fcn') };

      $! = 0; $_item = $_module->$_fcn(@{ $_item }) or return '';

      $_export_nul{ $_class } = undef if ($_class->isa('Graphics::Framebuffer'));
      $_export_nul{ $_class } = undef if ($_fcn eq 'TIEHANDLE');

      return '' if (
         $_has_args && $_fcn eq 'TIEHANDLE' && !defined(fileno $_item)
      );
   }
   elsif ($_class eq ':construct_pdl:') {
      local $@; local $SIG{__DIE__};

      $_class = 'PDL', $_item = eval q{
         unless ($INC{'PDL.pm'}) {
            use PDL;
            # Disable PDL auto-threading.
            eval q{ PDL::set_autopthread_targ(1) };
         }

         my $_func = pop @{ $_item };

         if    ($_func eq 'sbyte'    ) { sbyte     (@{ $_item }); }
         elsif ($_func eq 'byte'     ) { byte      (@{ $_item }); }
         elsif ($_func eq 'short'    ) { short     (@{ $_item }); }
         elsif ($_func eq 'ushort'   ) { ushort    (@{ $_item }); }
         elsif ($_func eq 'long'     ) { long      (@{ $_item }); }
         elsif ($_func eq 'ulong'    ) { ulong     (@{ $_item }); }
         elsif ($_func eq 'indx'     ) { indx      (@{ $_item }); }
         elsif ($_func eq 'longlong' ) { longlong  (@{ $_item }); }
         elsif ($_func eq 'ulonglong') { ulonglong (@{ $_item }); }
         elsif ($_func eq 'float'    ) { float     (@{ $_item }); }
         elsif ($_func eq 'double'   ) { double    (@{ $_item }); }
         elsif ($_func eq 'ldouble'  ) { ldouble   (@{ $_item }); }
         elsif ($_func eq 'sequence' ) { sequence  (@{ $_item }); }
         elsif ($_func eq 'zeroes'   ) { zeroes    (@{ $_item }); }
         elsif ($_func eq 'zeros'    ) { zeros     (@{ $_item }); }
         elsif ($_func eq 'ones'     ) { ones      (@{ $_item }); }
         elsif ($_func eq 'random'   ) { random    (@{ $_item }); }
         elsif ($_func eq 'grandom'  ) { grandom   (@{ $_item }); }
         else                          { pdl       (@{ $_item }); }
      };
   }

   $_all{ $_id } = $_class;
   $_ob3{"$_id:count"} = 1;

   if ($_class eq 'MCE::Shared::Handle' && reftype $_item eq 'ARRAY') {
      $_obj{ $_id } = IO::Handle->new();
      $_export_nul{ $_class } = undef;

      bless $_obj{ $_id }, $_class;
   }
   else {
      $_obj{ $_id } = $_item;

      if ( reftype $_obj{ $_id } eq 'HASH' &&
           reftype $_obj{ $_id }->{'fh'} eq 'GLOB' ) {

         if ( $_class->isa('Tie::File') ) {
            # enable autoflush, enable raw layer
            $_obj{ $_id }->{'fh'}->autoflush(1);
            binmode($_obj{ $_id }->{'fh'}, ':raw');
         }

         $_export_nul{ $_class } = undef;
      }
   }

   my $self = bless [ $_id, $_class ], 'MCE::Shared::Object';

   $_ob2{ $_id } = $_freeze->([ $self ]);

   if ( $_params->{tied} ) {
      # set encoder/decoder upon receipt in MCE::Shared::_tie
      for my $_module ( @_db_modules ) {
         $self->[2] = 1, last if $_class->isa($_module);
      }
      $_export_nul{ $_class } = undef if $self->[2];
   }

   return $self;
}

sub _start {
   return if $_svr_pid;

   if ($INC{'PDL.pm'}) { local $@;
      # PDL::IO::Storable is required for serializing piddles.
      eval 'use PDL::IO::Storable' unless $INC{'PDL/IO/Storable.pm'};
      # PDL data should not be naively copied in new threads.
      eval 'no warnings; sub PDL::CLONE_SKIP { 1 }';
      # Disable PDL auto-threading.
      eval q{ PDL::set_autopthread_targ(1) };
   }

   local $_;  $_init_pid = "$$.$_tid", $_stopped = undef;

   my $_data_channels = ($_init_pid eq $_oid) ? DATA_CHANNELS : 2;

   $_SVR = { _data_channels => $_data_channels };

   # Defaults to the misc channel used by _new, _get_hobo_data, and export.
   MCE::Util::_sock_pair($_SVR, qw(_dat_r_sock _dat_w_sock), 0);
   MCE::Util::_sock_pair($_SVR, qw(_dat_r_sock _dat_w_sock), $_, 1)
      for (1 .. $_data_channels + 1);

   setsockopt($_SVR->{_dat_r_sock}[0], SOL_SOCKET, SO_RCVBUF, 4096)
      if ($^O ne 'aix' && $^O ne 'linux');

   if ($_is_MSWin32) {
      for (1 .. $_data_channels + 1) {
         my $_mutex;
         $_SVR->{'_mutex_'.$_} = threads::shared::share($_mutex);
      }
   }
   else {
      $_SVR->{'_mutex_'.$_} = MCE::Mutex->new( impl => 'Channel' )
         for (1 .. $_data_channels + 1);
   }

   MCE::Shared::Object::_start();

   local $SIG{TTIN}, local $SIG{TTOU}, local $SIG{WINCH}
      unless $_is_MSWin32;

   if ($_spawn_child) {
      $_svr_pid = fork();
      _loop() if (defined $_svr_pid && $_svr_pid == 0);
   }
   else {
      $_svr_pid = threads->create(\&_loop);
      $_svr_pid->detach() if defined $_svr_pid;
   }

   _croak("cannot start the shared-manager process: $!")
      unless (defined $_svr_pid);

   sleep 0.015 if (!$_spawn_child || $_is_MSWin32);

   return;
}

sub _stop {
   $_stopped = 1;
   return unless ($_is_client && $_init_pid && $_init_pid eq "$$.$_tid");

   MCE::Child->finish('MCE') if $INC{'MCE/Child.pm'};
   MCE::Hobo->finish('MCE')  if $INC{'MCE/Hobo.pm'};

   local ($!, $?, $@);

   if (defined $_svr_pid) {
      my $_DAT_W_SOCK = $_SVR->{_dat_w_sock}[0];

      if (ref $_svr_pid) {
         eval { $_svr_pid->kill('KILL') };
      }
      else {
         local $SIG{HUP} = local $SIG{QUIT} = local $SIG{PIPE} =
         local $SIG{INT} = local $SIG{TERM} = sub {};

         my $_start = time;

         eval {
            local $\ = undef if (defined $\);
            print {$_DAT_W_SOCK} SHR_M_STP.$LF.'0'.$LF;
         };

         while () {
            last if waitpid($_svr_pid, _WNOHANG);
            if ( time - $_start > 0.7 ) {
               CORE::kill('USR2', $_svr_pid);
               waitpid($_svr_pid, 0);
               last;
            }
            sleep 0.045;
         }
      }

      $_init_pid = $_svr_pid = undef;
      %_all = (), %_obj = ();

      MCE::Util::_destroy_socks($_SVR, qw( _dat_w_sock _dat_r_sock ));

      for my $_i (1 .. $_SVR->{_data_channels} + 1) {
         delete $_SVR->{'_mutex_'.$_i};
      }

      MCE::Shared::Object::_stop();
   }

   return;
}

sub _pid {
   return ref($_svr_pid) ? int($_init_pid) : $_svr_pid;
}

sub _destroy {
   my ($_lkup, $_item, $_id) = @_;

   # safety for circular references to not destroy dangerously
   return if exists $_ob3{ "$_id:count" } && --$_ob3{ "$_id:count" } > 0;

   # safety for circular references to not loop endlessly
   return if exists $_lkup->{ $_id };

   $_lkup->{ $_id } = undef;

   if (exists $_ob3{ "$_id:deeply" }) {
      for my $_oid (keys %{ $_ob3{ "$_id:deeply" } }) {
         _destroy($_lkup, $_obj{ $_oid }, $_oid);
      }
      delete $_ob3{ "$_id:deeply" };
   }
   elsif (exists $_obj{ $_id }) {
      if ($_obj{ $_id }->isa('MCE::Shared::Scalar') ||
          $_obj{ $_id }->isa('Tie::StdScalar')) {

         if (blessed($_item->FETCH())) {
            my $_oid = $_item->FETCH()->SHARED_ID();
            _destroy($_lkup, $_obj{ $_oid }, $_oid);
         }

         undef ${ $_obj{ $_id } };
      }
      elsif ($_obj{ $_id }->isa('Tie::File')) { $_obj{ $_id }->flush();   }
      elsif ($_obj{ $_id }->can('sync'))      { $_obj{ $_id }->sync();    }
      elsif ($_obj{ $_id }->can('db_sync'))   { $_obj{ $_id }->db_sync(); }
      elsif ($_obj{ $_id }->can('close'))     { $_obj{ $_id }->close();   }
      elsif ($_obj{ $_id }->can('DESTROY'))   { delete $_obj{ $_id };     }
      elsif (reftype $_obj{ $_id } eq 'GLOB') {
         close $_obj{ $_id } if defined(fileno $_obj{ $_id });
      }
   }

   weaken( delete $_obj{ $_id } ) if exists($_obj{ $_id });
   weaken( delete $_itr{ $_id } ) if exists($_itr{ $_id });

   delete($_itr{ "$_id:args"  }), delete($_all{ $_id }),
   delete($_ob3{ "$_id:count" }), delete($_ob2{ $_id });

   return;
}

###############################################################################
## ----------------------------------------------------------------------------
## Server loop.
##
###############################################################################

sub _exit {
   $SIG{__DIE__}  = sub {} unless $_tid;
   $SIG{__WARN__} = sub {};

   # Flush file handles.
   for my $_id ( keys %_obj ) {
      eval {
         if    ($_obj{ $_id }->isa('Tie::File')) { $_obj{ $_id }->flush();   }
         elsif ($_obj{ $_id }->can('sync'))      { $_obj{ $_id }->sync();    }
         elsif ($_obj{ $_id }->can('db_sync'))   { $_obj{ $_id }->db_sync(); }
         elsif ($_obj{ $_id }->can('close'))     { $_obj{ $_id }->close();   }
         elsif ($_obj{ $_id }->can('DESTROY'))   { delete $_obj{ $_id };     }
         elsif (reftype $_obj{ $_id } eq 'GLOB') {
            close $_obj{ $_id } if defined(fileno $_obj{ $_id });
         }
      };
   }

   # Destroy non-exportable objects.
   for my $_id ( keys %_all ) {
      eval {
         weaken( delete $_obj{ $_id } )
            if ( exists $_export_nul{ $_all{ $_id } } );
      };
   }

   # Wait for the main thread to exit.
   if ( !$_spawn_child && ($_is_MSWin32 || $INC{'Tk.pm'} || $INC{'Wx.pm'}) ) {
      sleep 1.0;
   }

   threads->exit(0) if ( !$_spawn_child || $_is_MSWin32 );

   CORE::kill('KILL', $$) unless $_is_MSWin32;
   CORE::exit(0);
}

sub _loop {
   $_is_client = 0;

   $MCE::MCE = undef if ($MCE::MCE && $MCE::MCE->{_wid} == 0);

   local $\ = undef; local $/ = $LF; $| = 1;
   my $_running_inside_eval = $^S;

   local $SIG{TERM} = local $SIG{QUIT} = local $SIG{INT} = local $SIG{HUP} = sub {}
      if ($_init_pid eq $_oid);

   local $SIG{PIPE} = sub { $SIG{PIPE} = sub {}; CORE::kill('PIPE', getppid()); }
      if ($_spawn_child && !$_is_MSWin32);

   local $SIG{USR2} = \&_exit if ($_init_pid eq $_oid && !$_is_MSWin32);
   local $SIG{KILL} = \&_exit if ($_init_pid eq $_oid && !$_spawn_child);

   local $SIG{__DIE__} = sub {
      if (!defined $^S || $^S) {
         if ( ($INC{'threads.pm'} && threads->tid() != 0) ||
               $ENV{'PERL_IPERL_RUNNING'} ||
               $_running_inside_eval
         ) {
            # thread env or running inside IPerl, check stack trace
            my $_t = Carp::longmess(); $_t =~ s/\teval [^\n]+\n$//;
            CORE::die(@_)
               if ( $_t =~ /^(?:[^\n]+\n){1,7}\teval / ||
                    $_t =~ /\n\teval [^\n]+\n\t(?:eval|Try)/ );
         }
         else {
            # normal env, trust $^S
            CORE::die(@_);
         }
      }

      $SIG{INT} = $SIG{__DIE__} = $SIG{__WARN__} = sub {};
      print {*STDERR} defined $_[0] ? $_[0] : '';

      ( $_spawn_child && !$_is_MSWin32 )
         ? CORE::kill('KILL', -getpgrp)
         : CORE::exit($?);
   };

   my ($_id, $_fcn, $_wa, $_len, $_func, $_var);
   my ($_channel_id, $_done) = (0, 0);

   my $_channels   = $_SVR->{_dat_r_sock};
   my $_DAT_R_SOCK = $_SVR->{_dat_r_sock}[0];
   my $_DAU_R_SOCK;

   my $_auto_reply = sub {
      if ( $_wa == WA_ARRAY ) {
         my @_ret = eval { $_var->$_fcn(@_) };
         my $_buf = $_freeze->(\@_ret);
         return print {$_DAU_R_SOCK} length($_buf).$LF, $_buf;
      }

      my $_ret = eval { $_var->$_fcn(@_) };
      my $_buf = $_freeze->([ $_ret ]);

      print {$_DAU_R_SOCK} length($_buf).$LF, $_buf;
   };

   my $_obj_keys = sub {
      my ( $_obj, @_keys, $_cnt ) = ( shift );

      return keys %{ $_obj } if $_obj->isa('Tie::StdHash');
      return (0 .. $_obj->FETCHSIZE - 1) unless $_obj->can('FIRSTKEY');

      if ( wantarray ) {
         my $_key = $_obj->FIRSTKEY;
         if ( defined $_key ) {
            push @_keys, $_key;
            # CDB_File expects the $_key argument
            while ( defined( $_key = $_obj->NEXTKEY($_key) ) ) {
               push @_keys, $_key;
            }
         }
      }
      elsif ( $_obj->isa('Tie::ExtraHash') ) {
         $_cnt = keys %{ $_obj->[0] };
      }
      elsif ( $_obj->isa('Tie::IxHash') ) {
         $_cnt = keys %{ $_obj->[2] };
      }
      else {
         my $_key = $_obj->FIRSTKEY; $_cnt = 0;
         if ( defined $_key ) {
            $_cnt = 1;
            # CDB_File expects the $_key argument
            while ( defined( $_key = $_obj->NEXTKEY($_key) ) ) {
               $_cnt++;
            }
         }
      }

      wantarray ? @_keys : $_cnt;
   };

   my $_iter = sub {
      unless ( exists $_itr{ $_id } ) {

         my $pkg = $_all{ $_id };
         my $flg = ($pkg->can('NEXTKEY') || $pkg->can('keys')) ? 1 : 0;
         my $get = $pkg->can('FETCH') ? 'FETCH' : $pkg->can('get') ? 'get' : '';

         unless ( ($flg || $pkg->can('FETCHSIZE')) && $get ) {
            print {$_DAU_R_SOCK} '-1'.$LF;
            return;
         }

         # MCE::Shared::{ Array, Cache, Hash, Ordhash }, Hash::Ordered,
         # or similar module.

         $get = 'peek' if $pkg->isa('MCE::Shared::Cache');

         if ( !exists $_itr{ "$_id:args" } ) {
            @{ $_itr{ "$_id:args" } } = $pkg->can('keys')
               ? $_obj{ $_id }->keys()
               : $_obj_keys->( $_obj{ $_id } );
         }
         else {
            my $_args = $_itr{ "$_id:args" };
            if ( @{ $_args } == 1 &&
                 $_args->[0] =~ /^(?:key|val)[ ]+\S\S?[ ]+\S/ ) {

               @{ $_args } = $_obj{ $_id }->keys($_args->[0])
                  if $pkg->isa('MCE::Shared::Base::Common');
            }
            else {
               $_obj{ $_id }->_prune_head()
                  if $pkg->isa('MCE::Shared::Cache');
            }
         }

         $_itr{ $_id } = sub {
            my $_key = shift @{ $_itr{ "$_id:args" } };
            print({$_DAU_R_SOCK} '-1'.$LF), return if !defined($_key);
            my $_buf = $_freeze->([ $_key, $_obj{ $_id }->$get($_key) ]);
            print {$_DAU_R_SOCK} length($_buf).$LF, $_buf;
         };
      }

      $_itr{ $_id }->();

      return;
   };

   my $_warn = sub {
      if ( $_wa ) {
         my $_buf = $_freeze->([ ]);
         print {$_DAU_R_SOCK} length($_buf).$LF, $_buf;
      }
   };

   # --------------------------------------------------------------------------

   my %_output_function; %_output_function = (

      SHR_M_NEW.$LF => sub {                      # New share
         my ($_buf, $_params, $_class, $_args, $_fd, $_item);

         chomp($_len = <$_DAU_R_SOCK>),
         read($_DAU_R_SOCK, $_buf, $_len);

         $_params = Storable::thaw($_buf);
         $_class  = $_params->{'class'};

         { local $@; MCE::Shared::_use($_params->{module} || $_class); }

         chomp($_len = <$_DAU_R_SOCK>), read($_DAU_R_SOCK, $_buf, $_len),
         chomp($_len = <$_DAU_R_SOCK>), print({$_DAU_R_SOCK} $LF);

         $_args = Storable::thaw($_buf); undef $_buf;

         if ($_len) {
            $_export_nul{ $_class } = undef;

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

         $_item = _share($_params, @{ $_args }) or do {
            print {$_DAU_R_SOCK} int($!).$LF . '0'.$LF;
            return;
         };

         $_buf = $_freeze->($_item);

         print {$_DAU_R_SOCK} $_item->SHARED_ID().$LF .
            length($_buf).$LF, $_buf;

         if ($_class eq 'MCE::Shared::Queue') {
            MCE::Shared::Queue::_init_mgr(
               \$_DAU_R_SOCK, \%_obj, \%_output_function, $_freeze, $_thaw
            ) if $INC{'MCE/Shared/Queue.pm'};
         }
         elsif (reftype $_obj{ $_item->[0] } eq 'GLOB') {
            MCE::Shared::Handle::_init_mgr(
               \$_DAU_R_SOCK, \%_obj, \%_output_function, $_freeze, $_thaw
            ) if $INC{'MCE/Shared/Handle.pm'};
         }
         elsif ($_class eq 'MCE::Shared::Condvar') {
            MCE::Shared::Condvar::_init_mgr(
               \$_DAU_R_SOCK, \%_obj, \%_output_function
            ) if $INC{'MCE/Shared/Condvar.pm'};
         }

         return;
      },

      SHR_M_CID.$LF => sub {                      # ClientID request
         print {$_DAU_R_SOCK} (++$_channel_id).$LF;
         $_channel_id = 0 if ($_channel_id >= $_SVR->{_data_channels});

         return;
      },

      SHR_M_DEE.$LF => sub {                      # Deeply shared
         chomp(my $_id1 = <$_DAU_R_SOCK>),
         chomp(my $_id2 = <$_DAU_R_SOCK>);

         $_ob3{ "$_id1:deeply" }->{ $_id2 } = undef;

         return;
      },

      SHR_M_INC.$LF => sub {                      # Increment count
         chomp($_id = <$_DAU_R_SOCK>);

         $_ob3{ "$_id:count" }++;
         print {$_DAU_R_SOCK} $LF;

         return;
      },

      SHR_M_OBJ.$LF => sub {                      # Object request
         chomp($_id  = <$_DAU_R_SOCK>),
         chomp($_fcn = <$_DAU_R_SOCK>),
         chomp($_wa  = <$_DAU_R_SOCK>),
         chomp($_len = <$_DAU_R_SOCK>),

         read($_DAU_R_SOCK, my($_buf), $_len);

         $_var = $_obj{ $_id } || do { return $_warn->($_fcn) };

         $_wa  ? $_auto_reply->(@{ $_thaw->($_buf) })
               : eval { $_var->$_fcn(@{ $_thaw->($_buf) }) };

         warn $@ if $@;
         return;
      },

      SHR_M_OB0.$LF => sub {                      # Object request - thaw'less
         chomp($_id  = <$_DAU_R_SOCK>),
         chomp($_fcn = <$_DAU_R_SOCK>),
         chomp($_wa  = <$_DAU_R_SOCK>);

         $_var = $_obj{ $_id } || do { return $_warn->($_fcn) };

         my $_code = $_var->can($_fcn) || do {
            if ( ($_fcn eq 'keys' || $_fcn eq 'SCALAR') &&
                 ($_var->can('NEXTKEY') || $_var->can('FETCHSIZE')) ) {
               $_obj_keys;
            }
            else {
               $_wa ? $_auto_reply->() : eval { $_var->$_fcn() };
               warn $@ if $@;
               return;
            }
         };

         if ( $_wa == WA_ARRAY ) {
            my @_ret = eval { $_code->($_var) };
            my $_buf = $_freeze->(\@_ret);
            print {$_DAU_R_SOCK} length($_buf).$LF, $_buf;
         }
         elsif ( $_wa ) {
            my $_ret = eval { $_code->($_var) };
            my $_buf = $_freeze->([ $_ret ]);
            print {$_DAU_R_SOCK} length($_buf).$LF, $_buf;
         }
         else {
            eval { $_code->($_var) };
         }

         warn $@ if $@;
         return;
      },

      SHR_M_DES.$LF => sub {                      # Destroy request
         chomp($_id = <$_DAU_R_SOCK>);

         local $SIG{__DIE__};
         local $SIG{__WARN__};

         $_var = undef; local $@;

         eval {
            my $_ret = exists($_all{ $_id }) ? '1' : '0';
            _destroy({}, $_obj{ $_id }, $_id) if $_ret;
         };

         print {$_DAU_R_SOCK} $LF;

         return;
      },

      SHR_M_EXP.$LF => sub {                      # Export request
         chomp($_id  = <$_DAU_R_SOCK>),
         chomp($_len = <$_DAU_R_SOCK>);

         read($_DAU_R_SOCK, my($_keys), $_len) if $_len;

         if (exists $_obj{ $_id }) {
            my $_buf;

            # Do not export: e.g. objects with file handles
            if ( exists $_export_nul{ $_all{ $_id } } ) {
               print {$_DAU_R_SOCK} '-1'.$LF;
               return;
            }

            # MCE::Shared::{ Array, Hash, Ordhash }, Hash::Ordered
            if ($_obj{ $_id }->can('clone')) {
               $_buf = ($_len)
                  ? Storable::freeze($_obj{ $_id }->clone(@{ $_thaw->($_keys) }))
                  : Storable::freeze($_obj{ $_id });
            }
            # Other
            else {
               $_buf = Storable::freeze($_obj{ $_id });
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
            my $_buf = $_freeze->([ $_code->($_var) ]);
            print {$_DAU_R_SOCK} length($_buf).$LF, $_buf;
         }
         else {
            $_iter->();
         }

         return;
      },

      SHR_M_IRW.$LF => sub {                      # Iterator rewind
         chomp($_id  = <$_DAU_R_SOCK>),
         chomp($_len = <$_DAU_R_SOCK>),

         read($_DAU_R_SOCK, my($_buf), $_len);

         my $_var = $_obj{ $_id };

         if ( my $_code = $_var->can('rewind') ) {
            $_code->($_var, @{ $_thaw->($_buf) });
         }
         else {
            weaken( delete $_itr{ $_id } ) if ( exists $_itr{ $_id } );
            my @_args = @{ $_thaw->($_buf) };
            if ( @_args ) {
               $_itr{ "$_id:args" } = \@_args;
            } else {
               delete $_itr{ "$_id:args" };
            }
         }

         print {$_DAU_R_SOCK} $LF;

         return;
      },

      SHR_M_STP.$LF => sub {                      # Exit loop
         $SIG{USR2} = sub {} unless $_is_MSWin32;

         $_done = 1;

         return;
      },

      SHR_O_PDL.$LF => sub {                      # PDL::ins inplace(this),...
         chomp($_id  = <$_DAU_R_SOCK>),
         chomp($_len = <$_DAU_R_SOCK>),

         read($_DAU_R_SOCK, my($_buf), $_len);

         if ($_all{ $_id } eq 'PDL') {
            # PDL ins( inplace($this), $what, @coords );
            local @_ = @{ Storable::thaw($_buf) };

            if (@_ == 1) {
               ins( inplace($_obj{ $_id }), @_, 0, 0 );
            }
            elsif (@_ == 2 && $_[0] =~ /^:,(\d+):(\d+)/ && ref($_[1])) {
               my $_s = $2 - $1;
               ins( inplace($_obj{ $_id }), $_[1]->slice(":,0:$_s"), 0, $1 );
            }
            elsif (!ref($_[0]) && $_[0] =~ /^(\d+)$/) {
               $_obj{ $_id }->set(@_);
            }
            elsif (@_ == 2) {
               $_[0] =~ /^:,(\d+)/;
               ins( inplace($_obj{ $_id }), $_[1], 0, $1 // $_[0] );
            }
            elsif (@_ > 2) {
               ins( inplace($_obj{ $_id }), @_ );
            }
         }

         return;
      },

      SHR_O_DAT.$LF => sub {                      # Get MCE::Hobo data
         my $_key;

         chomp($_id  = <$_DAU_R_SOCK>),
         chomp($_key = <$_DAU_R_SOCK>);

         my $error  = delete $_obj{ $_id }{ 'S'.$_key } // '';
         my $result = delete $_obj{ $_id }{ 'R'.$_key } // '';

         print {$_DAU_R_SOCK}
            length($error).$LF . length($result).$LF . $error, $result;

         return;
      },

      SHR_O_CLR.$LF => sub {                      # Clear
         chomp($_id  = <$_DAU_R_SOCK>),
         chomp($_fcn = <$_DAU_R_SOCK>);

         my $_var = $_obj{ $_id } || do { return };

         if (exists $_ob3{ "$_id:deeply" }) {
            my $_keep = { $_id => 1 };
            for my $_oid (keys %{ $_ob3{ "$_id:deeply" } }) {
               _destroy($_keep, $_obj{ $_oid }, $_oid);
            }
            delete $_ob3{ "$_id:deeply" };
         }

         eval { $_var->$_fcn() };

         warn $@ if $@;
         return;
      },

      SHR_O_FCH.$LF => sub {                      # Fetch
         chomp($_id  = <$_DAU_R_SOCK>),
         chomp($_fcn = <$_DAU_R_SOCK>),
         chomp($_len = <$_DAU_R_SOCK>);

         read($_DAU_R_SOCK, my($_key), $_len) if $_len;

         my $_var = $_obj{ $_id } || do {
            return print {$_DAU_R_SOCK} '-1'.$LF;
         };

         my $_buf = $_len
            ? eval { $_var->$_fcn( chop $_key ? ${ $_thaw->($_key) } : $_key ) }
            : eval { $_var->$_fcn() };

         warn $@ if $@;

         return print {$_DAU_R_SOCK} '-1'.$LF if ( !defined $_buf );

         my $_ret = ( blessed($_buf) && $_buf->can('SHARED_ID') && $_ob2{ $_buf->[0] } ) 
            ? $_ob2{ $_buf->[0] }
            : $_freeze->([ $_buf ]);

         print {$_DAU_R_SOCK} length($_ret).$LF, $_ret;

         return;
      },

      SHR_O_SZE.$LF => sub {                      # Size
         chomp($_id  = <$_DAU_R_SOCK>),
         chomp($_fcn = <$_DAU_R_SOCK>);

         $_var = $_obj{ $_id } || do {
             print {$_DAU_R_SOCK} $LF if $_wa;
             return;
         };

         my $_code = $_var->can($_fcn) || do {
            if ( ($_fcn eq 'keys' || $_fcn eq 'SCALAR') &&
                 ($_var->can('NEXTKEY') || $_var->can('FETCHSIZE')) ) {
               $_obj_keys;
            }
            else {
               $_len = eval { $_var->$_fcn() };
               print {$_DAU_R_SOCK} $_len.$LF;

               warn $@ if $@;
               return;
            }
         };

         $_len = eval { $_code->($_var) };
         print {$_DAU_R_SOCK} $_len.$LF;

         warn $@ if $@;
         return;
      },

   );

   MCE::Shared::Queue::_init_mgr(
      \$_DAU_R_SOCK, \%_obj, \%_output_function, $_freeze, $_thaw
   ) if $INC{'MCE/Shared/Queue.pm'};

   MCE::Shared::Handle::_init_mgr(
      \$_DAU_R_SOCK, \%_obj, \%_output_function, $_freeze, $_thaw
   ) if $INC{'MCE/Shared/Handle.pm'};

   MCE::Shared::Condvar::_init_mgr(
      \$_DAU_R_SOCK, \%_obj, \%_output_function
   ) if $INC{'MCE/Shared/Condvar.pm'};

   # --------------------------------------------------------------------------

   # Call on hash function.

   if ($_is_MSWin32) {
      # The normal loop hangs on Windows when processes/threads start/exit.
      # Using ioctl() properly, https://www.perlmonks.org/?node_id=780083

      my $_val_bytes = "\x00\x00\x00\x00";
      my $_ptr_bytes = unpack( 'I', pack('P', $_val_bytes) );
      my ($_count, $_nbytes, $_start);

      while (!$_done) {
         $_start = time, $_count = 1;

         # MSWin32 FIONREAD
         IOCTL: ioctl($_DAT_R_SOCK, 0x4004667f, $_ptr_bytes);

         unless ($_nbytes = unpack('I', $_val_bytes)) {
            if ($_count) {
                # delay after a while to not consume a CPU core
                $_count = 0 if ++$_count % 50 == 0 && time - $_start > 0.030;
            } else {
                sleep 0.015;
            }
            goto IOCTL;
         }

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

use Scalar::Util qw( looks_like_number reftype );
use MCE::Shared::Base ();
use bytes;

use constant {
   _WNOHANG => ( $INC{'POSIX.pm'} )
      ? &POSIX::WNOHANG : ( $^O eq 'solaris' ) ? 64 : 1
};
use constant {
   _ID    => 0, _CLASS => 1, _ENCODE => 2, _DECODE => 3, # shared object
   _DREF  => 4, _ITER  => 5, _MUTEX  => 6,
};
use constant {
   _UNDEF => 0, _ARRAY => 1, _SCALAR => 2, # wantarray
};

## Below, no circular reference to original, therefore no memory leaks.

use overload (
   q("")    => \&MCE::Shared::Base::_stringify,
   q(0+)    => \&MCE::Shared::Base::_numify,
   q(@{})   => sub {
      no overloading;
      $_[0]->[_DREF] || do {
         local $@; my $c = $_[0]->[_CLASS];
         ($c) = $c =~ /(.*)/; # remove tainted'ness
         return $_[0] unless eval qq{ eval { require $c }; $c->can('TIEARRAY') };
         tie my @a, __PACKAGE__, bless([ @{ $_[0] }[ 0..3 ] ], __PACKAGE__);
         $_[0]->[_DREF] = \@a;
      };
   },
   q(%{})   => sub {
      no overloading;
      $_[0]->[_DREF] || do {
         local $@; my $c = $_[0]->[_CLASS];
         ($c) = $c =~ /(.*)/; # remove tainted'ness
         return $_[0] unless eval qq{ eval { require $c }; $c->can('TIEHASH') };
         tie my %h, __PACKAGE__, bless([ @{ $_[0] }[ 0..3 ] ], __PACKAGE__);
         $_[0]->[_DREF] = \%h;
      };
   },
   q(${})   => sub {
      no overloading;
      $_[0]->[_DREF] || do {
         local $@; my $c = $_[0]->[_CLASS];
         ($c) = $c =~ /(.*)/; # remove tainted'ness
         return $_[0] unless eval qq{ eval { require $c }; $c->can('TIESCALAR') };
         tie my $s, __PACKAGE__, bless([ @{ $_[0] }[ 0..3 ] ], __PACKAGE__);
         $_[0]->[_DREF] = \$s;
      };
   },
   fallback => 1
);

no overloading;

my ($_DAT_LOCK, $_DAT_W_SOCK, $_DAU_W_SOCK, $_chn, $_dat_ex, $_dat_un);

my $_blessed = \&Scalar::Util::blessed;

BEGIN {
   $_dat_ex = sub { _croak (
      "\nPlease start the shared-manager process manually when ready.\n",
      "See section labeled \"Extra Functionality\" in MCE::Shared.\n\n"
   ) };
}

# Hook for threads.

sub CLONE {
   $_tid = threads->tid() if $INC{'threads.pm'};
   &_init($_tid) if $_tid;
}

# Private functions.

sub DESTROY {
   return if $_stopped;
   return unless ( $_is_client && defined $_svr_pid && defined $_[0] );

   if ( $_spawn_child && $_init_pid && $_init_pid eq "$$.$_tid" ) {
      local ($!, $?);
      return if ( ! $_svr_pid || waitpid($_svr_pid, _WNOHANG) );
   }

   my $_id = $_[0]->[_ID];

   if ( exists $_new{ $_id } ) {
      my $_pid = $_tid ? $$ .'.'. $_tid : $$;

      if ($_new{ $_id } eq $_pid) {
         return if $MCE::Signal::KILLED;

         delete($_all{ $_id }), delete($_obj{ $_id }),
         delete($_new{ $_id }), delete($_ob2{ $_id }),
         delete($_ob3{"$_id:count"});

         _req1('M~DES', $_id.$LF);
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
   MCE::Shared::Object::_init_condvar(
      $_DAT_LOCK, $_DAT_W_SOCK, $_DAU_W_SOCK, $_dat_ex, $_dat_un, $_chn, \%_obj,
      $_freeze, $_thaw
   ) if $INC{'MCE/Shared/Condvar.pm'};

   MCE::Shared::Object::_init_handle(
      $_DAT_LOCK, $_DAT_W_SOCK, $_DAU_W_SOCK, $_dat_ex, $_dat_un, $_chn, \%_obj,
      $_freeze, $_thaw
   ) if $INC{'MCE/Shared/Handle.pm'};

   MCE::Shared::Object::_init_queue(
      $_DAT_LOCK, $_DAT_W_SOCK, $_DAU_W_SOCK, $_dat_ex, $_dat_un, $_chn, \%_obj,
      $_freeze, $_thaw
   ) if $INC{'MCE/Shared/Queue.pm'};
}

sub _start {
   $_chn        = $_SVR->{_data_channels} + 1;
   $_DAT_LOCK   = $_SVR->{'_mutex_'.$_chn};
   $_DAT_W_SOCK = $_SVR->{_dat_w_sock}[0];
   $_DAU_W_SOCK = $_SVR->{_dat_w_sock}[$_chn];

   # inlined for performance
   $_dat_ex = sub {
      my $_pid = $_tid ? $$ .'.'. $_tid : $$;
      MCE::Util::_sock_ready($_DAT_LOCK->{_r_sock}) if $_is_MSWin32;
      MCE::Util::_sysread($_DAT_LOCK->{_r_sock}, my($b), 1), $_DAT_LOCK->{ $_pid } = 1
         unless $_DAT_LOCK->{ $_pid };
   };
   $_dat_un = sub {
      my $_pid = $_tid ? $$ .'.'. $_tid : $$;
      CORE::syswrite($_DAT_LOCK->{_w_sock}, '0'), $_DAT_LOCK->{ $_pid } = 0
         if $_DAT_LOCK->{ $_pid };
   };

   _reset();
}

sub _stop {
   $_DAT_LOCK = $_DAT_W_SOCK = $_DAU_W_SOCK = $_chn = $_dat_un = undef;

   $_dat_ex = sub { _croak (
      "\nPlease start the shared-manager process manually when ready.\n",
      "See section labeled \"Extra Functionality\" in MCE::Shared.\n\n"
   ) };

   return;
}

sub _get_channel_id {
   local $\ = undef if (defined $\);
   local $/ = $LF if ($/ ne $LF);
   local $MCE::Signal::SIG;

   my $_ret;

   {
      local $MCE::Signal::IPC = 1;
      $_is_MSWin32 ? CORE::lock $_DAT_LOCK : $_dat_ex->();

      print {$_DAT_W_SOCK} 'M~CID'.$LF . $_chn.$LF;
      chomp($_ret = <$_DAU_W_SOCK>);

      $_dat_un->() if !$_is_MSWin32;
   }

   CORE::kill($MCE::Signal::SIG, $$) if $MCE::Signal::SIG;

   return $_ret;
}

sub _init {
   return unless defined $_SVR;

   my $_id = $_[0] // &_get_channel_id();
      $_id = $$ if ( $_id !~ /\d+/ );

   $_chn        = abs($_id) % $_SVR->{_data_channels} + 1;
   $_DAT_LOCK   = $_SVR->{'_mutex_'.$_chn};
   $_DAU_W_SOCK = $_SVR->{_dat_w_sock}[$_chn];

   %_new = (), _reset();

   return;
}

###############################################################################
## ----------------------------------------------------------------------------
## Private routines.
##
###############################################################################

# Called by AUTOLOAD, STORE, set, and keys.

sub _auto {
   my $_wa = !defined wantarray ? _UNDEF : wantarray ? _ARRAY : _SCALAR;

   local $\ = undef if (defined $\);
   local $MCE::Signal::SIG;

   my $_buf;

   {
      local $MCE::Signal::IPC = 1;
      $_is_MSWin32 ? CORE::lock $_DAT_LOCK : $_dat_ex->();

      if ( @_ == 2 ) {
         print({$_DAT_W_SOCK} 'M~OB0'.$LF . $_chn.$LF),
         print({$_DAU_W_SOCK} $_[1]->[_ID].$LF . $_[0].$LF . $_wa.$LF);
      }
      else {
         my ( $_fcn, $_id, $_buf ) = ( shift, shift()->[_ID], $_freeze->([ @_ ]) );
         my $_tmp = $_id.$LF . $_fcn.$LF . $_wa.$LF . length($_buf).$LF;
         print({$_DAT_W_SOCK} 'M~OBJ'.$LF . $_chn.$LF),
         print({$_DAU_W_SOCK} $_tmp, $_buf);
      }

      if ( $_wa ) {
         local $/ = $LF if ($/ ne $LF);
         chomp(my $_len = <$_DAU_W_SOCK>);
         read($_DAU_W_SOCK, $_buf, $_len);
      }

      $_dat_un->() if !$_is_MSWin32;
   }

   CORE::kill($MCE::Signal::SIG, $$) if $MCE::Signal::SIG;

   return unless $_wa;
   return ( $_wa != _ARRAY ) ? $_thaw->($_buf)[0] : @{ $_thaw->($_buf) };
}

# Called by MCE::Hobo ( ->join, ->wait_one ).

sub _get_hobo_data {
   if ( $_spawn_child && $_init_pid && $_init_pid eq "$$.$_tid" ) {
      local ($!, $?);
      return if ( ! $_svr_pid || waitpid($_svr_pid, _WNOHANG) );
   }

   local $\ = undef if (defined $\);
   local $/ = $LF if ($/ ne $LF);
   local $MCE::Signal::SIG;

   my ($_result, $_error);

   {
      local $MCE::Signal::IPC = 1;
      $_is_MSWin32 ? CORE::lock $_DAT_LOCK : $_dat_ex->();

      print({$_DAT_W_SOCK} 'O~DAT'.$LF . $_chn.$LF),
      print({$_DAU_W_SOCK} $_[0]->[_ID].$LF . $_[1].$LF);

      chomp(my $_le1 = <$_DAU_W_SOCK>),
      chomp(my $_le2 = <$_DAU_W_SOCK>);

      read($_DAU_W_SOCK, $_error,  $_le1) if $_le1;
      read($_DAU_W_SOCK, $_result, $_le2) if $_le2;

      $_dat_un->() if !$_is_MSWin32;
   }

   CORE::kill($MCE::Signal::SIG, $$) if $MCE::Signal::SIG;

   return ($_result, $_error);
}

# Called by await, rewind, broadcast, signal, timedwait, and wait.
# Including CLOSE, DESTROY, and destroy.

sub _req1 {
   return unless defined $_DAU_W_SOCK;  # (in cleanup)

   local $\ = undef if (defined $\);
   local $/ = $LF   if ($/ ne $LF );
   local $MCE::Signal::SIG;

   my $_ret;

   {
      local $MCE::Signal::IPC = 1;
      $_is_MSWin32 ? CORE::lock $_DAT_LOCK : $_dat_ex->();

      print({$_DAT_W_SOCK} $_[0].$LF . $_chn.$LF),
      print({$_DAU_W_SOCK} $_[1]);
      chomp($_ret = <$_DAU_W_SOCK>);

      $_dat_un->() if !$_is_MSWin32;
   }

   CORE::kill($MCE::Signal::SIG, $$) if $MCE::Signal::SIG;

   $_ret;
}

# Called by PRINT, PRINTF, STORE, ins_inplace, and set.

sub _req2 {
   local $\ = undef if (defined $\);
   local $MCE::Signal::SIG;

   {
      local $MCE::Signal::IPC = 1;
      $_is_MSWin32 ? CORE::lock $_DAT_LOCK : $_dat_ex->();

      print({$_DAT_W_SOCK} $_[0].$LF . $_chn.$LF),
      print({$_DAU_W_SOCK} $_[1], $_[2]);

      $_dat_un->() if !$_is_MSWin32;
   }

   CORE::kill($MCE::Signal::SIG, $$) if $MCE::Signal::SIG;

   1;
}

# Called by CLEAR and clear.

sub _req3 {
   my ( $_fcn, $self ) = @_;

   local $\ = undef if (defined $\);
   local $/ = $LF   if ($/ ne $LF );
   local $MCE::Signal::SIG;

   delete $self->[_ITER] if defined $self->[_ITER];

   {
      local $MCE::Signal::IPC = 1;
      $_is_MSWin32 ? CORE::lock $_DAT_LOCK : $_dat_ex->();

      print({$_DAT_W_SOCK} 'O~CLR'.$LF . $_chn.$LF),
      print({$_DAU_W_SOCK} $self->[_ID].$LF . $_fcn.$LF);

      $_dat_un->() if !$_is_MSWin32;
   }

   CORE::kill($MCE::Signal::SIG, $$) if $MCE::Signal::SIG;

   return;
}

# Called by FETCH and get.

sub _req4 {
   local $\ = undef if (defined $\);
   local $/ = $LF   if ($/ ne $LF );
   local $MCE::Signal::SIG;

   my ( $_key, $_len, $_buf );

   if ( @_ == 3 ) {
      $_key = ref($_[2]) ? $_[2].'0' : $_freeze->(\$_[2]).'1';
   }

   {
      local $MCE::Signal::IPC = 1;
      $_is_MSWin32 ? CORE::lock $_DAT_LOCK : $_dat_ex->();

      print({$_DAT_W_SOCK} 'O~FCH'.$LF . $_chn.$LF),
      print({$_DAU_W_SOCK} $_[1]->[_ID].$LF . $_[0].$LF . length($_key).$LF, $_key);
      chomp($_len = <$_DAU_W_SOCK>);

      read($_DAU_W_SOCK, $_buf, $_len) if ($_len >= 0);

      $_dat_un->() if !$_is_MSWin32;
   }

   CORE::kill($MCE::Signal::SIG, $$) if $MCE::Signal::SIG;

   return undef if ($_len < 0);

   if ( $_[1]->[_DECODE] && $_[0] eq 'FETCH' ) {
      local $@; $_buf = $_thaw->($_buf)[0];
      return eval { $_[1]->[_DECODE]->($_buf) } || $_buf;
   }

   $_thaw->($_buf)[0];
}

# Called by FETCHSIZE, SCALAR, keys, and pending.

sub _size {
   local $\ = undef if (defined $\);
   local $/ = $LF   if ($/ ne $LF );
   local $MCE::Signal::SIG;

   my $_size;

   {
      local $MCE::Signal::IPC = 1;
      $_is_MSWin32 ? CORE::lock $_DAT_LOCK : $_dat_ex->();

      print({$_DAT_W_SOCK} 'O~SZE'.$LF . $_chn.$LF),
      print({$_DAU_W_SOCK} $_[1]->[_ID].$LF . $_[0].$LF);
      chomp($_size = <$_DAU_W_SOCK>);

      $_dat_un->() if !$_is_MSWin32;
   }

   CORE::kill($MCE::Signal::SIG, $$) if $MCE::Signal::SIG;

   length($_size) ? int($_size) : undef;
}

###############################################################################
## ----------------------------------------------------------------------------
## Common methods.
##
###############################################################################

our $AUTOLOAD; # MCE::Shared::Object::<method_name>

sub AUTOLOAD {
   my $_fcn = $AUTOLOAD;  substr($_fcn, 0, rindex($_fcn,':') + 1, '');

   # save this method for future calls
   no strict 'refs';
   *{ $AUTOLOAD } = sub { _auto($_fcn, @_) };

   goto &{ $AUTOLOAD };
}

# blessed ( )

sub blessed {
   $_[0]->[_CLASS];
}

# decoder ( CODE )
# decoder ( )

sub decoder {
   $_[0]->[_DECODE] = $_[1] if (@_ == 2 && (ref $_[1] eq 'CODE' || !$_[1]));
   $_[0]->[_DECODE];
}

# encoder ( CODE )
# encoder ( )

sub encoder {
   $_[0]->[_ENCODE] = $_[1] if (@_ == 2 && (ref $_[1] eq 'CODE' || !$_[1]));
   $_[0]->[_ENCODE];
}

# destroy ( { unbless => 1 } )
# destroy ( )

sub destroy {
   my $_id   = $_[0]->[_ID];
   my $_un   = (ref $_[1] eq 'HASH' && $_[1]->{'unbless'}) ? 1 : 0;
   my $_item = (defined wantarray) ? $_[0]->export({ unbless => $_un }) : undef;
   my $_pid  = $_tid ? $$ .'.'. $_tid : $$;

   delete($_all{ $_id }), delete($_obj{ $_id });

   if (defined $_svr_pid && exists $_new{ $_id } && $_new{ $_id } eq $_pid) {
      delete($_new{ $_id }), _req1('M~DES', $_id.$LF);
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

   { local $@; MCE::Shared::_use($_class); }

   {
      local $\ = undef if (defined $\);
      local $/ = $LF if ($/ ne $LF);
      local $MCE::Signal::SIG;

      my $_len;

      {
         local $MCE::Signal::IPC = 1;
         $_is_MSWin32 ? CORE::lock $_DAT_LOCK : $_dat_ex->();

         print({$_DAT_W_SOCK} 'M~EXP'.$LF . $_chn.$LF),
         print({$_DAU_W_SOCK} $_buf, $_tmp); undef $_buf;
         chomp($_len = <$_DAU_W_SOCK>);

         read($_DAU_W_SOCK, $_buf, $_len) if ($_len >= 0);

         $_dat_un->() if !$_is_MSWin32;
      }

      CORE::kill($MCE::Signal::SIG, $$) if $MCE::Signal::SIG;

      return undef if ($_len < 0);

      $_item = $_lkup->{ $_id } = Storable::thaw($_buf);
      undef $_buf;
   }

   my $_data; local $_;

   ## no critic
   if ( $_class->isa('MCE::Shared::Array') || $_class->isa('Tie::StdArray') ) {
      map { $_ = $_->export($_lkup) if $_blessed->($_) && $_->can('export')
          } @{ $_item };

      return $_lkup->{ $_id } = [ @{ $_item } ] if $_lkup->{'unbless'};
   }
   elsif ( $_class->isa('MCE::Shared::Hash') || $_class->isa('Tie::StdHash') ) {
      map { $_ = $_->export($_lkup) if $_blessed->($_) && $_->can('export')
          } CORE::values %{ $_item };

      return $_lkup->{ $_id } = { %{ $_item } } if $_lkup->{'unbless'};
   }
   elsif ( $_class->isa('MCE::Shared::Scalar') || $_class->isa('Tie::StdScalar') ) {
      if ( $_blessed->(${ $_item }) && ${ $_item }->can('export') ) {
         ${ $_item } = ${ $_item }->export($_lkup);
      }
      return $_lkup->{ $_id } = \do { my $o = ${ $_item } } if $_lkup->{'unbless'};
   }
   else {
      if    ( $_class->isa('MCE::Shared::Ordhash') ) { $_data = $_item->[0] }
      elsif ( $_class->isa('MCE::Shared::Cache')   ) { $_data = $_item->[0] }
      elsif ( $_class->isa('Hash::Ordered')        ) { $_data = $_item->[0] }
      elsif ( $_class->isa('Tie::ExtraHash')       ) { $_data = $_item->[0] }
      elsif ( $_class->isa('Tie::IxHash')          ) { $_data = $_item->[2] }

      if ( reftype $_data eq 'ARRAY' ) {
         map { $_ = $_->export($_lkup) if $_blessed->($_) && $_->can('export')
             } @{ $_data };
      }
      elsif ( reftype $_data eq 'HASH' ) {
         map { $_ = $_->export($_lkup) if $_blessed->($_) && $_->can('export')
             } values %{ $_data };
      }
   }

   $_item;
}

# iterator ( index [, index, ... ] )  # Array
# iterator ( key [, key, ... ] )      # Cache, Hash, Ordhash
# iterator ( "query string" )         # Cache, Hash, Ordhash, Array
# iterator ( )

sub iterator {
   my ( $self, @keys ) = @_;

   my $pkg = $self->blessed();
   my $flg = ($pkg->can('NEXTKEY') || $pkg->can('keys')) ? 1 : 0;
   my $get = $pkg->can('FETCH') ? 'FETCH' : $pkg->can('get') ? 'get' : '';

   unless ( ($flg || $pkg->can('FETCHSIZE')) && $get ) {
      return sub {};
   }

   # MCE::Shared::{ Array, Cache, Hash, Ordhash }, Hash::Ordered,
   # or similar module.

   $get = 'peek' if $pkg->isa('MCE::Shared::Cache');

   if ( ! @keys ) {
      @keys = $self->keys;
   }
   elsif ( @keys == 1 && $keys[0] =~ /^(?:key|val)[ ]+\S\S?[ ]+\S/ ) {
      return sub {} unless $pkg->isa('MCE::Shared::Base::Common');
      @keys = $self->keys($keys[0]);
   }
   elsif ( $pkg->isa('MCE::Shared::Cache') ) {
      $self->_prune_head();
   }

   return sub {
      return unless @keys;
      my $key = shift @keys;
      return ( $key => $self->$get($key) );
   };
}

# rewind ( index [, index, ... ] )         # Array
# rewind ( key [, key, ... ] )             # Cache, Hash, Ordhash
# rewind ( "query string" )                # Cache, Hash, Ordhash, Array
# rewind ( begin, end [, step, format ] )  # Sequence
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
   local $MCE::Signal::SIG;

   my ( $_len, $_buf );

   {
      local $MCE::Signal::IPC = 1;
      $_is_MSWin32 ? CORE::lock $_DAT_LOCK : $_dat_ex->();

      print({$_DAT_W_SOCK} 'M~INX'.$LF . $_chn.$LF),
      print({$_DAU_W_SOCK} $_[0]->[_ID].$LF);
      chomp($_len = <$_DAU_W_SOCK>);

      read($_DAU_W_SOCK, $_buf, $_len) if ($_len >= 0);

      $_dat_un->() if !$_is_MSWin32;
   }

   CORE::kill($MCE::Signal::SIG, $$) if $MCE::Signal::SIG;

   return if ($_len < 0);

   my $_b; return wantarray ? () : undef unless @{ $_b = $_thaw->($_buf) };

   if ( $_[0]->[_DECODE] ) {
      local $@; $_b->[-1] = eval { $_[0]->[_DECODE]->($_b->[-1]) } || $_b->[-1];
   }

   ( wantarray )
      ? @{ $_b } == 2 ? ( $_b->[0], delete $_b->[-1] ) : @{ $_b }
      : delete $_b->[-1];
}

###############################################################################
## ----------------------------------------------------------------------------
## Methods optimized for:
##  MCE::Shared::{ Array, Hash, Ordhash, Scalar } and similar.
##
###############################################################################

sub ins_inplace {
   my $_id = shift()->[_ID];

   if ( @_ ) {
      my $_tmp = Storable::freeze([ @_ ]);
      my $_buf = $_id.$LF . length($_tmp).$LF;
      _req2('O~PDL', $_buf, $_tmp);
   }

   return;
}

sub FETCHSIZE { _size('FETCHSIZE', @_) }
sub SCALAR    { _size('SCALAR'   , @_) }
sub CLEAR     { _req3('CLEAR'    , @_) }
sub FETCH     { _req4('FETCH'    , @_) }

sub clear {
   @_ > 1 ? _auto('clear', @_) : _req3('clear', @_);
}
sub get {
   @_ > 2 ? _auto('get', @_) : _req4('get', @_);
}

sub FIRSTKEY {
   $_[0]->[_ITER] = [ $_[0]->keys ];
   shift @{ $_[0]->[_ITER] };
}
sub NEXTKEY {
   shift @{ $_[0]->[_ITER] };
}

sub STORE {
   if ( @_ > 1 && $_[0]->[_ENCODE] ) {
      $_[-1] = $_[0]->[_ENCODE]->($_[-1]) if ref($_[-1]);
   }
   elsif ( @_ == 2 && $_blessed->($_[1]) && $_[1]->can('SHARED_ID') ) {
      _req2('M~DEE', $_[0]->[_ID].$LF, $_[1]->SHARED_ID().$LF);
      delete $_new{ $_[1]->SHARED_ID() };
   }
   elsif ( ref $_[2] ) {
      if ( $_blessed->($_[2]) && $_[2]->can('SHARED_ID') ) {
         _req2('M~DEE', $_[0]->[_ID].$LF, $_[2]->SHARED_ID().$LF);
         delete $_new{ $_[2]->SHARED_ID() };
      }
      elsif ( $_[0]->[1]->isa('MCE::Shared::Array') ||
              $_[0]->[1]->isa('MCE::Shared::Hash') ) {
         $_[2] = MCE::Shared::share({ _DEEPLY_ => 1 }, $_[2]);
         _req2('M~DEE', $_[0]->[_ID].$LF, $_[2]->SHARED_ID().$LF);
      }
   }
   _auto('STORE', @_); 1;
}

sub set {
   if ( ref $_[2] ) {
      if ( $_blessed->($_[2]) && $_[2]->can('SHARED_ID') ) {
         _req2('M~DEE', $_[0]->[_ID].$LF, $_[2]->SHARED_ID().$LF);
         delete $_new{ $_[2]->SHARED_ID() };
      }
   }
   _auto('set', @_);
}

sub keys {
   ( @_ == 1 && !wantarray ) ? _size('keys', @_) : _auto('keys', @_);
}

sub lock {
   my ( $self ) = @_;
   Carp::croak( sprintf(
      "Mutex not enabled for the shared %s instance", $self->[_CLASS]
   )) unless $self->[_MUTEX];

   $self->[_MUTEX]->lock();
}

sub unlock {
   my ( $self ) = @_;
   Carp::croak( sprintf(
      "Mutex not enabled for the shared %s instance", $self->[_CLASS]
   )) unless $self->[_MUTEX];

   $self->[_MUTEX]->unlock();
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

This document describes MCE::Shared::Server version 1.880

=head1 DESCRIPTION

The core engine for L<MCE::Shared>. See documentation there.

=head1 INDEX

L<MCE|MCE>, L<MCE::Hobo>, L<MCE::Shared>

=head1 AUTHOR

Mario E. Roy, S<E<lt>marioeroy AT gmail DOT comE<gt>>

=cut

