###############################################################################
## ----------------------------------------------------------------------------
## Handle helper class.
##
###############################################################################

package MCE::Shared::Handle;

use strict;
use warnings;

use 5.010001;

no warnings qw( threads recursion uninitialized numeric );

our $VERSION = '1.873';

## no critic (BuiltinFunctions::ProhibitStringyEval)
## no critic (InputOutput::ProhibitTwoArgOpen)
## no critic (Subroutines::ProhibitExplicitReturnUndef)
## no critic (Subroutines::ProhibitSubroutinePrototypes)
## no critic (TestingAndDebugging::ProhibitNoStrict)

use MCE::Shared::Base ();

my $LF = "\012"; Internals::SvREADONLY($LF, 1);
my $_tid = $INC{'threads.pm'} ? threads->tid() : 0;
my $_max_fd = eval 'fileno(\*main::DATA)' // 2;
my $_reset_flg = 1;

sub _croak {
   goto &MCE::Shared::Base::_croak;
}
sub CLONE {
   $_tid = threads->tid() if $INC{'threads.pm'};
}

sub import {
   if (!defined $INC{'MCE/Shared.pm'}) {
      no strict 'refs'; no warnings 'redefine';
      *{ caller().'::mce_open' } = \&open;
   }
   return;
}

sub TIEHANDLE {
   my $class = shift;

   if (ref $_[0] eq 'ARRAY') {
      # For use with MCE::Shared in order to reach the Server process.
      # Therefore constructed without a GLOB handle initially.

      MCE::Shared::Object::_reset(), $_reset_flg = ''
         if $_reset_flg && $INC{'MCE/Shared/Server.pm'};

      return bless $_[0], $class;
   }

   bless my $fh = \do { no warnings 'once'; local *FH }, $class;

   if (@_) {
      if ( !defined wantarray ) {
         $fh->OPEN(@_) or _croak("open error: $!");
      } else {
         $fh->OPEN(@_) or return '';
      }
   }

   $fh;
}

###############################################################################
## ----------------------------------------------------------------------------
## Based on Tie::StdHandle.
##
###############################################################################

sub EOF     { eof($_[0]) }
sub TELL    { tell($_[0]) }
sub FILENO  { fileno($_[0]) }
sub SEEK    { seek($_[0], $_[1], $_[2]) }
sub CLOSE   { close($_[0]) if defined(fileno $_[0]) }
sub BINMODE { binmode($_[0], $_[1] // ':raw') ? 1 : '' }
sub GETC    { getc($_[0]) }

sub OPEN {
   my $ret;

   close($_[0]) if defined fileno($_[0]);

   if ( @_ == 3 && ref $_[2] && defined( my $_fd = fileno($_[2]) ) ) {
      $ret = CORE::open($_[0], $_[1]."&=$_fd");
   }
   else {
      $ret = ( @_ == 2 )
         ? CORE::open($_[0], $_[1])
         : CORE::open($_[0], $_[1], $_[2]);
   }

   # enable autoflush
   select(( select($_[0]), $| = 1 )[0]) if $ret;

   $ret;
}

sub open (@) {
   shift if ( defined $_[0] && $_[0] eq 'MCE::Shared::Handle' );

   my $item;

   if ( ref $_[0] eq 'GLOB' && tied *{ $_[0] } &&
        ref tied(*{ $_[0] }) eq __PACKAGE__ ) {
      $item = tied *{ $_[0] };
   }
   elsif ( @_ ) {
      if ( ref $_[0] eq 'GLOB' && tied *{ $_[0] } ) {
         close $_[0] if defined ( fileno $_[0] );
      }
      $_[0] = \do { no warnings 'once'; local *FH };
      $item = tie *{ $_[0] }, __PACKAGE__;
   }

   shift; _croak("Not enough arguments for open") unless @_;

   if ( !defined wantarray ) {
      $item->OPEN(@_) or _croak("open error: $!");
   } else {
      $item->OPEN(@_);
   }
}

sub READ {
   my ($fh, $len, $auto) = ($_[0], $_[2]);

   if (lc(substr $len, -1, 1) eq 'm') {
      $auto = 1, chop $len;  $len *= 1024 * 1024;
   } elsif (lc(substr $len, -1, 1) eq 'k') {
      $auto = 1, chop $len;  $len *= 1024;
   }

   # normal use-case

   if (!$auto) {
      return @_ == 4 ? read($fh, $_[1], $len, $_[3]) : read($fh, $_[1], $len);
   }

   # chunk IO, read up to record separator or eof
   # support special case; e.g. $/ = "\n>" for bioinformatics
   # anchoring ">" at the start of line

   my ($tmp, $ret);

   if (!eof($fh)) {
      if (length $/ > 1 && substr($/, 0, 1) eq "\n") {
         my $len = length($/) - 1;

         if (tell $fh) {
            $tmp = substr($/, 1);
            $ret = read($fh, $tmp, $len, length($tmp));
         } else {
            $ret = read($fh, $tmp, $len);
         }

         if (defined $ret) {
            $.   += 1 if eof($fh);
            $tmp .= readline($fh);

            substr($tmp, -$len, $len, '')
               if (substr($tmp, -$len) eq substr($/, 1));
         }
      }
      elsif (defined ($ret = CORE::read($fh, $tmp, $len))) {
         $.   += 1 if eof($fh);
         $tmp .= readline($fh);
      }
   }
   else {
      $tmp = '', $ret = 0;
   }

   if (defined $ret) {
      my $pos = $_[3] || 0;
      substr($_[1], $pos, length($_[1]) - $pos, $tmp);
      length($tmp);
   }
   else {
      undef;
   }
}

sub READLINE {
   # support special case; e.g. $/ = "\n>" for bioinformatics
   # anchoring ">" at the start of line

   if (length $/ > 1 && substr($/, 0, 1) eq "\n" && !eof($_[0])) {
      my ($len, $buf) = (length($/) - 1);

      if (tell $_[0]) {
         $buf = substr($/, 1), $buf .= readline($_[0]);
      } else {
         $buf = readline($_[0]);
      }

      substr($buf, -$len, $len, '')
         if (substr($buf, -$len) eq substr($/, 1));

      $buf;
   }
   else {
      scalar(readline($_[0]));
   }
}

sub PRINT {
   my $fh  = shift;
   my $buf = join(defined $, ? $, : "", @_);
   $buf   .= $\ if defined $\;
   local $\; # don't print any line terminator
   print $fh $buf;
}

sub PRINTF {
   my $fh  = shift;
   my $buf = sprintf(shift, @_);
   local $\; # ditto
   print $fh $buf;
}

sub WRITE {
   use bytes;

   # based on IO::SigGuard::syswrite 0.011 by Felipe Gasper (FELIPE)
   my $wrote = 0;

   WRITE: {
      $wrote += (
        ( @_ == 2 )
          ? syswrite($_[0], $_[1], length($_[1]) - $wrote, $wrote)
          : ( @_ == 3 )
              ? syswrite($_[0], $_[1], $_[2] - $wrote, $wrote)
              : syswrite($_[0], $_[1], $_[2] - $wrote, $_[3] + $wrote)
      ) or do {
         unless ( defined $wrote ) {
            redo WRITE if $!{EINTR} || $!{EAGAIN} || $!{EWOULDBLOCK};
            return undef;
         }
      };
   }

   $wrote;
}

{
   no strict 'refs'; *{ __PACKAGE__.'::new' } = \&TIEHANDLE;
}

###############################################################################
## ----------------------------------------------------------------------------
## Server functions.
##
###############################################################################

{
   use constant {
      SHR_O_CLO => 'O~CLO',  # Handle CLOSE
      SHR_O_OPN => 'O~OPN',  # Handle OPEN
      SHR_O_REA => 'O~REA',  # Handle READ
      SHR_O_RLN => 'O~RLN',  # Handle READLINE
      SHR_O_PRI => 'O~PRI',  # Handle PRINT
      SHR_O_WRI => 'O~WRI',  # Handle WRITE
   };

   my (
      $_DAU_R_SOCK_REF, $_DAU_R_SOCK, $_obj, $_freeze, $_thaw,
      $_id, $_len, $_ret
   );

   my %_output_function = (

      SHR_O_CLO.$LF => sub {                      # Handle CLOSE
         $_DAU_R_SOCK = ${ $_DAU_R_SOCK_REF };
         chomp($_id = <$_DAU_R_SOCK>);

         close $_obj->{ $_id } if defined fileno($_obj->{ $_id });
         print {$_DAU_R_SOCK} '1'.$LF;

         return;
      },

      SHR_O_OPN.$LF => sub {                      # Handle OPEN
         $_DAU_R_SOCK = ${ $_DAU_R_SOCK_REF };
         my ($_fd, $_buf, $_err); local $!;

         chomp($_id  = <$_DAU_R_SOCK>),
         chomp($_fd  = <$_DAU_R_SOCK>),
         chomp($_len = <$_DAU_R_SOCK>),

         read($_DAU_R_SOCK, $_buf, $_len);
         print {$_DAU_R_SOCK} $LF;

         if ($_fd > $_max_fd) {
            $_fd = IO::FDPass::recv(fileno $_DAU_R_SOCK); $_fd >= 0
               or _croak("cannot receive file handle: $!");
         }

         close $_obj->{ $_id } if defined fileno($_obj->{ $_id });

         my $_args = $_thaw->($_buf);
         my $_fh;

         if (@{ $_args } == 2) {
            # remove tainted'ness from $_args
            ($_args->[0]) = $_args->[0] =~ /(.*)/;
            ($_args->[1]) = $_args->[1] =~ /(.*)/;

            CORE::open($_fh, "$_args->[0]", $_args->[1]) or do { $_err = 0+$! };
         }
         else {
            # remove tainted'ness from $_args
            ($_args->[0]) = $_args->[0] =~ /(.*)/;

            CORE::open($_fh, $_args->[0]) or do { $_err = 0+$! };
         }

         # enable autoflush
         select(( select($_fh), $| = 1 )[0]) unless $_err;

         *{ $_obj->{ $_id } } = *{ $_fh };
         print {$_DAU_R_SOCK} $_err.$LF;

         return;
      },

      SHR_O_REA.$LF => sub {                      # Handle READ
         $_DAU_R_SOCK = ${ $_DAU_R_SOCK_REF };
         my ($_a3, $_auto);

         chomp($_id  = <$_DAU_R_SOCK>),
         chomp($_a3  = <$_DAU_R_SOCK>),
         chomp($_len = <$_DAU_R_SOCK>);

         if (lc(substr $_a3, -1, 1) eq 'm') {
            $_auto = 1, chop $_a3;  $_a3 *= 1024 * 1024;
         } elsif (lc(substr $_a3, -1, 1) eq 'k') {
            $_auto = 1, chop $_a3;  $_a3 *= 1024;
         }

         local $/; read($_DAU_R_SOCK, $/, $_len) if $_len;
         my ($_fh, $_buf) = ($_obj->{ $_id }); local ($!, $.);

         # support special case; e.g. $/ = "\n>" for bioinformatics
         # anchoring ">" at the start of line

         if (!$_auto) {
            $. = 0, $_ret = read($_fh, $_buf, $_a3);
         }
         elsif (!eof($_fh)) {
            if (length $/ > 1 && substr($/, 0, 1) eq "\n") {
               $_len = length($/) - 1;

               if (tell $_fh) {
                  $_buf = substr($/, 1);
                  $_ret = read($_fh, $_buf, $_a3, length($_buf));
               } else {
                  $_ret = read($_fh, $_buf, $_a3);
               }

               if (defined $_ret) {
                  $.    += 1 if eof($_fh);
                  $_buf .= readline($_fh);

                  substr($_buf, -$_len, $_len, '')
                     if (substr($_buf, -$_len) eq substr($/, 1));
               }
            }
            elsif (defined ($_ret = read($_fh, $_buf, $_a3))) {
               $.    += 1 if eof($_fh);
               $_buf .= readline($_fh);
            }
         }
         else {
            $_buf = '', $_ret = 0;
         }

         if (defined $_ret) {
            $_ret = length($_buf), $_buf = $_freeze->(\$_buf);
            print {$_DAU_R_SOCK} "$.$LF" . length($_buf).$LF, $_buf, $_ret.$LF;
         }
         else {
            print {$_DAU_R_SOCK} "$.$LF" . ( (0+$!) * -1 ).$LF;
         }

         return;
      },

      SHR_O_RLN.$LF => sub {                      # Handle READLINE
         $_DAU_R_SOCK = ${ $_DAU_R_SOCK_REF };

         chomp($_id  = <$_DAU_R_SOCK>),
         chomp($_len = <$_DAU_R_SOCK>);

         local $/; read($_DAU_R_SOCK, $/, $_len) if $_len;
         my ($_fh, $_buf) = ($_obj->{ $_id }); local ($!, $.);

         # support special case; e.g. $/ = "\n>" for bioinformatics
         # anchoring ">" at the start of line

         if (length $/ > 1 && substr($/, 0, 1) eq "\n" && !eof($_fh)) {
            $_len = length($/) - 1;

            if (tell $_fh) {
               $_buf = substr($/, 1), $_buf .= readline($_fh);
            } else {
               $_buf = readline($_fh);
            }

            substr($_buf, -$_len, $_len, '')
               if (substr($_buf, -$_len) eq substr($/, 1));
         }
         else {
            $_buf = readline($_fh);
         }

         if (defined $_buf) {
            $_buf = $_freeze->(\$_buf);
            print {$_DAU_R_SOCK} "$.$LF" . length($_buf).$LF, $_buf;
         } else {
            print {$_DAU_R_SOCK} "$.$LF" . ( (0+$!) * -1 ).$LF;
         }

         return;
      },

      SHR_O_PRI.$LF => sub {                      # Handle PRINT
         $_DAU_R_SOCK = ${ $_DAU_R_SOCK_REF };

         chomp($_id  = <$_DAU_R_SOCK>),
         chomp($_len = <$_DAU_R_SOCK>),

         read($_DAU_R_SOCK, my($_buf), $_len);
         print {$_obj->{ $_id }} ${ $_thaw->($_buf) };

         return;
      },

      SHR_O_WRI.$LF => sub {                      # Handle WRITE
         $_DAU_R_SOCK = ${ $_DAU_R_SOCK_REF };
         use bytes;

         chomp($_id  = <$_DAU_R_SOCK>),
         chomp($_len = <$_DAU_R_SOCK>),

         read($_DAU_R_SOCK, my($_buf), $_len);

         my $_wrote = 0;

         WRITE: {
            $_wrote += ( syswrite (
               $_obj->{ $_id }, $_buf, length($_buf) - $_wrote, $_wrote
            )) or do {
               unless ( defined $_wrote ) {
                  redo WRITE if $!{EINTR} || $!{EAGAIN} || $!{EWOULDBLOCK};
                  print {$_DAU_R_SOCK} ''.$LF;

                  return;
               }
            };
         }

         print {$_DAU_R_SOCK} $_wrote.$LF;

         return;
      },

   );

   sub _init_mgr {
      my $_function;
      ( $_DAU_R_SOCK_REF, $_obj, $_function, $_freeze, $_thaw ) = @_;

      for my $key ( keys %_output_function ) {
         last if exists($_function->{$key});
         $_function->{$key} = $_output_function{$key};
      }

      return;
   }
}

###############################################################################
## ----------------------------------------------------------------------------
## Object package.
##
###############################################################################

## Items below are folded into MCE::Shared::Object.

package # hide from rpm
   MCE::Shared::Object;

use strict;
use warnings;

no warnings qw( threads recursion uninitialized numeric once );

use bytes;

no overloading;

my $_is_MSWin32 = ($^O eq 'MSWin32') ? 1 : 0;

my ($_DAT_LOCK, $_DAT_W_SOCK, $_DAU_W_SOCK, $_dat_ex, $_dat_un, $_chn, $_obj,
    $_freeze, $_thaw);

sub _init_handle {
   ($_DAT_LOCK, $_DAT_W_SOCK, $_DAU_W_SOCK, $_dat_ex, $_dat_un, $_chn, $_obj,
    $_freeze, $_thaw) = @_;

   return;
}

sub CLOSE {
   _req1('O~CLO', $_[0]->[0].$LF);
}

sub OPEN {
   my ($_id, $_fd, $_buf) = (shift()->[0]);
   return unless defined $_[0];

   if (ref $_[-1] && reftype($_[-1]) ne 'GLOB') {
      _croak("open error: not a GLOB reference");
   }
   elsif (@_ == 1 && ref $_[0] && defined($_fd = fileno($_[0]))) {
      $_buf = $_freeze->([ "<&=$_fd" ]);
   }
   elsif (@_ == 2 && ref $_[1] && defined($_fd = fileno($_[1]))) {
      $_buf = $_freeze->([ $_[0]."&=$_fd" ]);
   }
   elsif (!ref $_[-1]) {
      $_fd  = ($_[-1] =~ /&=(\d+)$/) ? $1 : -1;
      $_buf = $_freeze->([ @_ ]);
   }
   else {
      _croak("open error: unsupported use-case");
   }

   if ($_fd > $_max_fd && !$INC{'IO/FDPass.pm'}) {
      _croak(
         "\nSharing a handle object while the server is running\n",
         "requires the IO::FDPass module.\n\n"
      );
   }

   local $\ = undef if (defined $\);
   local $/ = $LF if ($/ ne $LF);
   local $MCE::Signal::SIG;

   my $_err;

   {
      local $MCE::Signal::IPC = 1;
      $_is_MSWin32 ? CORE::lock $_DAT_LOCK : $_dat_ex->();

      print({$_DAT_W_SOCK} 'O~OPN'.$LF . $_chn.$LF),
      print({$_DAU_W_SOCK} $_id.$LF . $_fd.$LF . length($_buf).$LF . $_buf);
      <$_DAU_W_SOCK>;

      IO::FDPass::send( fileno $_DAU_W_SOCK, fileno $_fd ) if ($_fd > $_max_fd);
      chomp($_err = <$_DAU_W_SOCK>);

      $_dat_un->() if !$_is_MSWin32;
   }

   CORE::kill($MCE::Signal::SIG, $$) if $MCE::Signal::SIG;

   if ($_err) {
      $! = $_err;
      '';
   } else {
      $! = 0;
      1;
   }
}

sub READ {
   local $\ = undef if (defined $\);
   local $MCE::Signal::SIG;

   my ($_len, $_ret);

   {
      local $MCE::Signal::IPC = 1;
      $_is_MSWin32 ? CORE::lock $_DAT_LOCK : $_dat_ex->();

      print({$_DAT_W_SOCK} 'O~REA'.$LF . $_chn.$LF),
      print({$_DAU_W_SOCK} $_[0]->[0].$LF . $_[2].$LF . length($/).$LF . $/);

      local $/ = $LF if ($/ ne $LF);
      chomp($_ret = <$_DAU_W_SOCK>);
      chomp($_len = <$_DAU_W_SOCK>);

      if ($_len && $_len > 0) {
         read($_DAU_W_SOCK, my $_buf, $_len);
         chomp($_len = <$_DAU_W_SOCK>);

         my $_ref = \$_[1];
         if (defined $_[3]) {
            no bytes;
            substr($$_ref, $_[3], length($$_ref) - $_[3], '');
            substr($$_ref, $_[3], $_len, ${ $_thaw->($_buf) });
         }
         else {
            $$_ref = ${ $_thaw->($_buf) };
         }
      }

      $_dat_un->() if !$_is_MSWin32;
   }

   CORE::kill($MCE::Signal::SIG, $$) if $MCE::Signal::SIG;

   if ($_len) {
      if ($_len < 0) {
         $. = 0, $! = $_len * -1;
         return undef;
      }
   }
   else {
      my $_ref = \$_[1];
      if (defined $_[3]) {
         no bytes;
         substr($$_ref, $_[3], length($$_ref) - $_[3], '');
      }
      else {
         $$_ref = '';
      }
   }

   $. = $_ret, $! = 0;
   $_len;
}

sub READLINE {
   local $\ = undef if (defined $\);
   local $MCE::Signal::SIG;

   my ($_buf, $_len, $_ret);

   {
      local $MCE::Signal::IPC = 1;
      $_is_MSWin32 ? CORE::lock $_DAT_LOCK : $_dat_ex->();

      print({$_DAT_W_SOCK} 'O~RLN'.$LF . $_chn.$LF),
      print({$_DAU_W_SOCK} $_[0]->[0].$LF . length($/).$LF . $/);

      local $/ = $LF if ($/ ne $LF);
      chomp($_ret = <$_DAU_W_SOCK>);
      chomp($_len = <$_DAU_W_SOCK>);

      if ($_len && $_len > 0) {
         read($_DAU_W_SOCK, $_buf, $_len);
      }

      $_dat_un->() if !$_is_MSWin32;
   }

   CORE::kill($MCE::Signal::SIG, $$) if $MCE::Signal::SIG;

   if ($_len && $_len < 0) {
      $. = 0, $! = $_len * -1;
      return undef;
   }

   $. = $_ret, $! = 0;
   $_buf ? ${ $_thaw->($_buf) } : $_buf;
}

sub PRINT {
   no bytes;
   my $_id  = shift()->[0];
   my $_buf = join(defined $, ? $, : "", @_);

   $_buf .= $\ if defined $\;

   if (length $_buf) {
      $_buf = $_freeze->(\$_buf);
      _req2('O~PRI', $_id.$LF . length($_buf).$LF, $_buf);
   } else {
      1;
   }
}

sub PRINTF {
   no bytes;
   my $_id  = shift()->[0];
   my $_buf = sprintf(shift, @_);

   if (length $_buf) {
      $_buf = $_freeze->(\$_buf);
      _req2('O~PRI', $_id.$LF . length($_buf).$LF, $_buf);
   } else {
      1;
   }
}

sub WRITE {
   my $_id  = shift()->[0];

   local $\ = undef if (defined $\);
   local $/ = $LF if ($/ ne $LF);
   local $MCE::Signal::SIG;

   my $_ret;

   {
      local $MCE::Signal::IPC = 1;
      $_is_MSWin32 ? CORE::lock $_DAT_LOCK : $_dat_ex->();

      if (@_ == 1 || (@_ == 2 && $_[1] == length($_[0]))) {
         print({$_DAT_W_SOCK} 'O~WRI'.$LF . $_chn.$LF),
         print({$_DAU_W_SOCK} $_id.$LF . length($_[0]).$LF, $_[0]);
      }
      else {
         my $_buf = substr($_[0], ($_[2] || 0), $_[1]);
         print({$_DAT_W_SOCK} 'O~WRI'.$LF . $_chn.$LF),
         print({$_DAU_W_SOCK} $_id.$LF . length($_buf).$LF, $_buf);
      }

      chomp($_ret = <$_DAU_W_SOCK>);

      $_dat_un->() if !$_is_MSWin32;
   }

   CORE::kill($MCE::Signal::SIG, $$) if $MCE::Signal::SIG;

   (length $_ret) ? $_ret : undef;
}

1;

__END__

###############################################################################
## ----------------------------------------------------------------------------
## Module usage.
##
###############################################################################

=head1 NAME

MCE::Shared::Handle - Handle helper class

=head1 VERSION

This document describes MCE::Shared::Handle version 1.873

=head1 DESCRIPTION

A handle helper class for use as a standalone or managed by L<MCE::Shared>.

=head1 SYNOPSIS

 # non-shared or local construction for use by a single process
 # shorter, mce_open is an alias for MCE::Shared::Handle::open

 use MCE::Shared::Handle;

 MCE::Shared::Handle->open( my $fh, "<", "bio.fasta" )
    or die "open error: $!";
 MCE::Shared::Handle::open  my $fh, "<", "bio.fasta"
    or die "open error: $!";

 mce_open my $fh, "<", "bio.fasta" or die "open error: $!";

 # construction for sharing with other threads and processes
 # shorter, mce_open is an alias for MCE::Shared::open

 use MCE::Shared;

 MCE::Shared->open( my $fh, "<", "bio.fasta" )
    or die "open error: $!";
 MCE::Shared::open  my $fh, "<", "bio.fasta"
    or die "open error: $!";

 mce_open my $fh, "<", "bio.fasta" or die "open error: $!";

 # example, output is serialized, not garbled

 use MCE::Hobo;
 use MCE::Shared;

 mce_open my $ofh, ">>", \*STDOUT  or die "open error: $!";
 mce_open my $ifh, "<", "file.log" or die "open error: $!";

 sub parallel {
    $/ = "\n"; # can set the input record separator
    while (my $line = <$ifh>) {
       printf {$ofh} "[%5d] %s", $., $line;
    }
 }

 MCE::Hobo->create( \&parallel ) for 1 .. 4;

 $_->join() for MCE::Hobo->list();

 # handle functions

 my $bool = eof($ifh);
 my $off  = tell($ifh);
 my $fd   = fileno($ifh);
 my $char = getc($ifh);
 my $line = readline($ifh);

 binmode $ifh;
 seek $ifh, 10, 0;
 read $ifh, my($buf), 80;

 print  {$ofh} "foo\n";
 printf {$ofh} "%s\n", "bar";

 open $ofh, ">>", \*STDERR;
 syswrite $ofh, "shared handle to STDERR\n";

 close $ifh;
 close $ofh;

=head1 API DOCUMENTATION

=head2 MCE::Shared::Handle->new ( )

Called by MCE::Shared for constructing a shared-handle object.

=head2 open ( filehandle, expr )

=head2 open ( filehandle, mode, expr )

=head2 open ( filehandle, mode, reference )

In version 1.007 and later, constructs a new object by opening the file
whose filename is given by C<expr>, and associates it with C<filehandle>.
When omitting error checking at the application level, MCE::Shared emits
a message and stop if open fails.

 # non-shared or local construction for use by a single process

 use MCE::Shared::Handle;

 MCE::Shared::Handle->open( my $fh, "<", "file.log" ) or die "$!";
 MCE::Shared::Handle::open  my $fh, "<", "file.log"   or die "$!";

 mce_open my $fh, "<", "file.log" or die "$!"; # ditto

 # construction for sharing with other threads and processes

 use MCE::Shared;

 MCE::Shared->open( my $fh, "<", "file.log" ) or die "$!";
 MCE::Shared::open  my $fh, "<", "file.log"   or die "$!";

 mce_open my $fh, "<", "file.log" or die "$!"; # ditto

=head2 mce_open ( filehandle, expr )

=head2 mce_open ( filehandle, mode, expr )

=head2 mce_open ( filehandle, mode, reference )

Native Perl-like syntax to open a file for reading:

 # mce_open is exported by MCE::Shared or MCE::Shared::Handle.
 # It creates a shared file handle with MCE::Shared present
 # or a non-shared handle otherwise.

 mce_open my $fh, "< input.txt"     or die "open error: $!";
 mce_open my $fh, "<", "input.txt"  or die "open error: $!";
 mce_open my $fh, "<", \*STDIN      or die "open error: $!";

and for writing:

 mce_open my $fh, "> output.txt"    or die "open error: $!";
 mce_open my $fh, ">", "output.txt" or die "open error: $!";
 mce_open my $fh, ">", \*STDOUT     or die "open error: $!";

=head1 CHUNK IO

Starting with C<MCE::Shared> v1.007, chunk IO is possible for both non-shared
and shared handles. Chunk IO is enabled by the trailing 'k' or 'm' for read
size. Also, chunk IO supports the special "\n>"-like record separator.
That anchors ">" at the start of the line. Workers receive record(s) beginning
with ">" and ending with "\n".

 # non-shared handle ---------------------------------------------

 use MCE::Shared::Handle;

 mce_open my $fh, '<', 'bio.fasta' or die "open error: $!";

 # shared handle -------------------------------------------------

 use MCE::Shared;

 mce_open my $fh, '<', 'bio.fasta' or die "open error: $!";

 # 'k' or 'm' indicates kibiBytes (KiB) or mebiBytes (MiB) respectively.
 # Read continues reading until reaching the record separator or EOF.
 # Optionally, one may specify the record separator.

 $/ = "\n>";

 while ( read($fh, my($buf), '2k') ) {
    print "# chunk number: $.\n";
    print "$buf\n";
 }

C<$.> contains the chunk_id above or the record_number below. C<readline($fh)>
or C<$fh> may be used for reading a single record.

 while ( my $buf = <$fh> ) {
    print "# record number: $.\n";
    print "$buf\n";
 }

The following provides a parallel demonstration. Workers receive the next chunk
from the shared-manager process where the actual read takes place. MCE::Shared
also works with C<threads>, C<forks>, and likely other parallel modules.

 use MCE::Hobo;       # (change to) use threads; (or) use forks;
 use MCE::Shared;
 use feature qw( say );

 my $pattern  = 'something';
 my $hugefile = 'somehuge.log';

 my $result = MCE::Shared->array();
 mce_open my $fh, "<", $hugefile or die "open error: $!";

 sub task {
    # the trailing 'k' or 'm' for size enables chunk IO
    while ( read $fh, my( $slurp_chunk ), "640k" ) {
       my $chunk_id = $.;
       # process chunk only if a match is found; ie. fast scan
       # optionally, comment out the if statement and closing brace
       if ( $slurp_chunk =~ /$pattern/m ) {
          my @matches;
          while ( $slurp_chunk =~ /([^\n]+\n)/mg ) {
             my $line = $1; # save $1 to not lose the value
             push @matches, $line if ( $line =~ /$pattern/ );
          }
          $result->push( @matches ) if @matches;
       }
    }
 }

 MCE::Hobo->create('task') for 1 .. 4;

 # do something else

 MCE::Hobo->waitall();

 say $result->len();

For comparison, the same thing using C<MCE::Flow>. MCE workers read the file
directly when given a plain path, so will have lesser overhead. However, the
run time is similar if one were to pass a file handle instead to mce_flow_f.

The benefit of chunk IO is from lesser IPC for the shared-manager process
(above). Likewise, for the mce-manager process (below).

 use MCE::Flow;
 use feature qw( say );

 my $pattern  = 'something';
 my $hugefile = 'somehuge.log';

 my @result = mce_flow_f {
    max_workers => 4, chunk_size => '640k',
    use_slurpio => 1,
 },
 sub {
    my ( $mce, $slurp_ref, $chunk_id ) = @_;
    # process chunk only if a match is found; ie. fast scan
    # optionally, comment out the if statement and closing brace
    if ( $$slurp_ref =~ /$pattern/m ) {
       my @matches;
       while ( $$slurp_ref =~ /([^\n]+\n)/mg ) {
          my $line = $1; # save $1 to not lose the value
          push @matches, $line if ( $line =~ /$pattern/ );
       }
       MCE->gather( @matches ) if @matches;
    }
 }, $hugefile;

 say scalar( @result );

=head1 CREDITS

Implementation inspired by L<Tie::StdHandle>.

=head1 LIMITATIONS

Perl must have L<IO::FDPass> for constructing a shared C<condvar> or C<queue>
while the shared-manager process is running. For platforms where L<IO::FDPass>
isn't possible, construct C<condvar> and C<queue> before other classes.
On systems without C<IO::FDPass>, the manager process is delayed until sharing
other classes or started explicitly.

 use MCE::Shared;

 my $has_IO_FDPass = $INC{'IO/FDPass.pm'} ? 1 : 0;

 my $cv  = MCE::Shared->condvar();
 my $que = MCE::Shared->queue();

 MCE::Shared->start() unless $has_IO_FDPass;

Regarding mce_open, C<IO::FDPass> is needed for constructing a shared-handle
from a non-shared handle not yet available inside the shared-manager process.
The workaround is to have the non-shared handle made before the shared-manager
is started. Passing a file by reference is fine for the three STD* handles.

 # The shared-manager knows of \*STDIN, \*STDOUT, \*STDERR.

 mce_open my $shared_in,  "<",  \*STDIN;   # ok
 mce_open my $shared_out, ">>", \*STDOUT;  # ok
 mce_open my $shared_err, ">>", \*STDERR;  # ok
 mce_open my $shared_fh1, "<",  "/path/to/sequence.fasta";  # ok
 mce_open my $shared_fh2, ">>", "/path/to/results.log";     # ok

 mce_open my $shared_fh, ">>", \*NON_SHARED_FH;  # requires IO::FDPass

The L<IO::FDPass> module is known to work reliably on most platforms.
Install 1.1 or later to rid of limitations described above.

 perl -MIO::FDPass -le "print 'Cheers! Perl has IO::FDPass.'"

=head1 INDEX

L<MCE|MCE>, L<MCE::Hobo>, L<MCE::Shared>

=head1 AUTHOR

Mario E. Roy, S<E<lt>marioeroy AT gmail DOT comE<gt>>

=cut

