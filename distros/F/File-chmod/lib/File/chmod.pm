package File::chmod;
use strict;
use warnings;
use Carp;
use vars qw( $VAL $W $MODE );

use base 'Exporter';

our $VERSION = '0.42'; # VERSION

our @EXPORT    = (qw( chmod getchmod )); ## no critic ( ProhibitAutomaticExportation )
our @EXPORT_OK = (qw( symchmod lschmod getsymchmod getlschmod getmod ));

our $DEBUG     = 1;
our $UMASK     = 2;
our $MASK      = umask;


my ($SYM,$LS) = (1,2);
my %ERROR = (
  EDETMOD => "use of determine_mode is deprecated",
  ENEXLOC => "cannot set group execute on locked file",
  ENLOCEX => "cannot set file locking on group executable file",
  ENSGLOC => "cannot set-gid on locked file",
  ENLOCSG => "cannot set file locking on set-gid file",
  ENEXUID => "execute bit must be on for set-uid",
  ENEXGID => "execute bit must be on for set-gid",
  ENULSID => "set-id has no effect for 'others'",
  ENULSBG => "sticky bit has no effect for 'group'",
  ENULSBU => "sticky bit has no effect for 'user'",
);

sub getmod {
  my @return = map { (stat)[2] & 07777 } @_;
  return wantarray ? @return : $return[0];
}


sub chmod (@) { ## no critic ( Subroutines::ProhibitBuiltinHomonyms Subroutines::ProhibitSubroutinePrototypes )
  my $mode = shift;
  my $how = mode($mode);

  return symchmod($mode,@_) if $how == $SYM;
  return lschmod($mode,@_) if $how == $LS;
  return CORE::chmod($mode,@_);
}


sub getchmod {
  my $mode = shift;
  my $how = mode($mode);

  return getsymchmod($mode,@_) if $how == $SYM;
  return getlschmod($mode,@_) if $how == $LS;
  return wantarray ? (($mode) x @_) : $mode;
}


sub symchmod {
  my $mode = shift;

warnings::warnif 'deprecated', '$UMASK being true is deprecated'
  . ' it will be false by default in the future. This change'
  . ' is being made because this not the behavior of the unix command'
  . ' `chmod`. This warning can be disabled by putting explicitly'
  . ' setting $File::chmod::UMASK to false (0) to act like system chmod,'
  . ' or any non 2 true value see Github issue #5 '
  if $UMASK == 2;

  my @return = getsymchmod($mode,@_);
  my $ret = 0;
  for (@_){ $ret++ if CORE::chmod(shift(@return),$_) }
  return $ret;
}


sub getsymchmod {
  my $mode = shift;
  my @return;

  croak "symchmod received non-symbolic mode: $mode" if mode($mode) != $SYM;

  for (@_){
    local $VAL = getmod($_);

    for my $this (split /,/, $mode){
      local $W = 0;
      my $or;

      for (split //, $this){
        if (not defined $or and /[augo]/){
          /a/ and $W |= 7, next;
          /u/ and $W |= 1, next;
          /g/ and $W |= 2, next;
          /o/ and $W |= 4, next;
        }

        if (/[-+=]/){
          $W ||= 7;
          $or = (/[=+]/ ? 1 : 0);
          clear() if /=/;
          next;
        }

        croak "Bad mode $this" if not defined $or;
        croak "Unknown mode: $mode" if !/[ugorwxslt]/;

        /u/ and $or ? u_or() : u_not();
        /g/ and $or ? g_or() : g_not();
        /o/ and $or ? o_or() : o_not();
        /r/ and $or ? r_or() : r_not();
        /w/ and $or ? w_or() : w_not();
        /x/ and $or ? x_or() : x_not();
        /s/ and $or ? s_or() : s_not();
        /l/ and $or ? l_or() : l_not();
        /t/ and $or ? t_or() : t_not();
      }
    }
    $VAL &= ~$MASK if $UMASK;
    push @return, $VAL;
  }
  return wantarray ? @return : $return[0];
}


sub lschmod {
  my $mode = shift;

  return CORE::chmod(getlschmod($mode,@_),@_);
}


sub getlschmod {
  my $mode = shift;
  my $VAL = 0;

  croak "lschmod received non-ls mode: $mode" if mode($mode) != $LS;

  my ($u,$g,$o) = ($mode =~ /^.(...)(...)(...)$/);

  for ($u){
    $VAL |= 0400 if /r/;
    $VAL |= 0200 if /w/;
    $VAL |= 0100 if /[xs]/;
    $VAL |= 04000 if /[sS]/;
  }

  for ($g){
    $VAL |= 0040 if /r/;
    $VAL |= 0020 if /w/;
    $VAL |= 0010 if /[xs]/;
    $VAL |= 02000 if /[sS]/;
  }

  for ($o){
    $VAL |= 0004 if /r/;
    $VAL |= 0002 if /w/;
    $VAL |= 0001 if /[xt]/;
    $VAL |= 01000 if /[Tt]/;
  }

  return wantarray ? (($VAL) x @_) : $VAL;
}


sub mode {
  my $mode = shift;
  return 0 if $mode !~ /\D/;
  return $SYM if $mode =~ /[augo=+,]/;
  return $LS if $mode =~ /^.([r-][w-][xSs-]){2}[r-][w-][xTt-]$/;
  return $SYM;
}


sub determine_mode {
  carp $ERROR{EDECMOD};
  mode(@_);
}


sub clear {
  $W & 1 and $VAL &= 02077;
  $W & 2 and $VAL &= 05707;
  $W & 4 and $VAL &= 07770;
}


sub u_or {
  my $val = $VAL;
  $W & 2 and ($VAL |= (($val & 0700)>>3 | ($val & 04000)>>1));
  $W & 4 and ($VAL |= (($val & 0700)>>6));
}


sub u_not {
  my $val = $VAL;
  $W & 1 and $VAL &= ~(($val & 0700) | ($val & 05000));
  $W & 2 and $VAL &= ~(($val & 0700)>>3 | ($val & 04000)>>1);
  $W & 4 and $VAL &= ~(($val & 0700)>>6);
}


sub g_or {
  my $val = $VAL;
  $W & 1 and $VAL |= (($val & 070)<<3 | ($val & 02000)<<1);
  $W & 4 and $VAL |= ($val & 070)>>3;
}


sub g_not {
  my $val = $VAL;
  $W & 1 and $VAL &= ~(($val & 070)<<3 | ($val & 02000)<<1);
  $W & 2 and $VAL &= ~(($val & 070) | ($val & 02000));
  $W & 4 and $VAL &= ~(($val & 070)>>3);
}


sub o_or {
  my $val = $VAL;
  $W & 1 and $VAL |= (($val & 07)<<6);
  $W & 2 and $VAL |= (($val & 07)<<3);
}


sub o_not {
  my $val = $VAL;
  $W & 1 and $VAL &= ~(($val & 07)<<6);
  $W & 2 and $VAL &= ~(($val & 07)<<3);
  $W & 4 and $VAL &= ~($val & 07);
}


sub r_or {
  $W & 1 and $VAL |= 0400;
  $W & 2 and $VAL |= 0040;
  $W & 4 and $VAL |= 0004;
}


sub r_not {
  $W & 1 and $VAL &= ~0400;
  $W & 2 and $VAL &= ~0040;
  $W & 4 and $VAL &= ~0004;
}


sub w_or {
  $W & 1 and $VAL |= 0200;
  $W & 2 and $VAL |= 0020;
  $W & 4 and $VAL |= 0002;
}


sub w_not {
  $W & 1 and $VAL &= ~0200;
  $W & 2 and $VAL &= ~0020;
  $W & 4 and $VAL &= ~0002;
}


sub x_or {
  if ($VAL & 02000){ $DEBUG and carp($ERROR{ENEXLOC}), return }
  $W & 1 and $VAL |= 0100;
  $W & 2 and $VAL |= 0010;
  $W & 4 and $VAL |= 0001;
}


sub x_not {
  $W & 1 and $VAL &= ~0100;
  $W & 2 and $VAL &= ~0010;
  $W & 4 and $VAL &= ~0001;
}


sub s_or {
  if ($VAL & 02000){ $DEBUG and carp($ERROR{ENSGLOC}), return }
  if (not $VAL & 00100){ $DEBUG and carp($ERROR{ENEXUID}), return }
  if (not $VAL & 00010){ $DEBUG and carp($ERROR{ENEXGID}), return }
  $W & 1 and $VAL |= 04000;
  $W & 2 and $VAL |= 02000;
  $W & 4 and $DEBUG and carp $ERROR{ENULSID};
}


sub s_not {
  $W & 1 and $VAL &= ~04000;
  $W & 2 and $VAL &= ~02000;
  $W & 4 and $DEBUG and carp $ERROR{ENULSID};
}


sub l_or {
  if ($VAL & 02010){ $DEBUG and carp ($ERROR{ENLOCSG}), return }
  if ($VAL & 00010){ $DEBUG and carp ($ERROR{ENLOCEX}), return }
  $VAL |= 02000;
}


sub l_not {
  $VAL &= ~02000 if not $VAL & 00010;
}


sub t_or {
  $W & 1 and $DEBUG and carp $ERROR{ENULSBU};
  $W & 2 and $DEBUG and carp $ERROR{ENULSBG};
  $W & 4 and $VAL |= 01000;
}


sub t_not {
  $W & 1 and $DEBUG and carp $ERROR{ENULSBU};
  $W & 2 and $DEBUG and carp $ERROR{ENULSBG};
  $W & 4 and $VAL &= ~01000;
}


1;
# ABSTRACT: Implements symbolic and ls chmod modes

__END__

=pod

=head1 NAME

File::chmod - Implements symbolic and ls chmod modes

=head1 VERSION

version 0.42

=head1 SYNOPSIS

  use File::chmod;
  $File::chmod::UMASK = 0;
  # It is recommended that you explicitly set $File::chmod::UMASK
  # as the default will change in the future
  #
  # 0 is recommended to behave like system chmod
  # 1 if you want File::chmod to apply your environment set umask.
  # 2 is how we detect that it's internally set, undef will become the
  # default in the future, eventually a lexicaly scoped API may be designed

  # chmod takes all three types
  # these all do the same thing
  chmod(0666,@files);
  chmod("=rw",@files);
  chmod("-rw-rw-rw-",@files);

  # or

  use File::chmod qw( symchmod lschmod );

  chmod(0666,@files);		# this is the normal chmod
  symchmod("=rw",@files);	# takes symbolic modes only
  lschmod("-rw-rw-rw-",@files);	# takes "ls" modes only

  # more functions, read on to understand

=head1 DESCRIPTION

File::chmod is a utility that allows you to bypass system calls or bit
processing of a file's permissions.  It overloads the chmod() function
with its own that gets an octal mode, a symbolic mode (see below), or
an "ls" mode (see below).  If you wish not to overload chmod(), you can
export symchmod() and lschmod(), which take, respectively, a symbolic
mode and an "ls" mode.

An added feature to version 0.30 is the C<$UMASK> variable, explained in
detail below; if C<symchmod()> is called and this variable is true, then the
function uses the (also new) C<$MASK> variable (which defaults to C<umask()>)
as a mask against the new mode. This mode is on by default, and changes the
behavior from what you would expect if you are used to UNIX C<chmod>.
B<This may change in the future.>

Symbolic modes are thoroughly described in your chmod(1) man page, but
here are a few examples.

  chmod("+x","file1","file2");	# overloaded chmod(), that is...
  # turns on the execute bit for all users on those two files

  chmod("o=,g-w","file1","file2");
  # removes 'other' permissions, and the write bit for 'group'

  chmod("=u","file1","file2");
  # sets all bits to those in 'user'

"ls" modes are the type produced on the left-hand side of an C<ls -l> on a
directory.  Examples are:

  chmod("-rwxr-xr-x","file1","file2");
  # the 0755 setting; user has read-write-execute, group and others
  # have read-execute priveleges

  chmod("-rwsrws---","file1","file2");
  # sets read-write-execute for user and group, none for others
  # also sets set-uid and set-gid bits

The regular chmod() and lschmod() are absolute; that is, they are not
appending to or subtracting from the current file mode.  They set it,
regardless of what it had been before.  symchmod() is useful for allowing
the modifying of a file's permissions without having to run a system call
or determining the file's permissions, and then combining that with whatever
bits are appropriate.  It also operates separately on each file.

=head1 FUNCTIONS - EXPORT

=head2 chmod(MODE,FILES)

Takes an octal, symbolic, or "ls" mode, and then chmods each file
appropriately.

=head2 getchmod(MODE,FILES)

Returns a list of modified permissions, without chmodding files.
Accepts any of the three kinds of modes.

  @newmodes = getchmod("+x","file1","file2");
  # @newmodes holds the octal permissions of the files'
  # modes, if they were to be sent through chmod("+x"...)

=head1 FUNCTIONS - EXPORT_OK

=head2 symchmod(MODE,FILES)

Takes a symbolic permissions mode, and chmods each file.

=head2 lschmod(MODE,FILES)

Takes an "ls" permissions mode, and chmods each file.

=head2 getsymchmod(MODE,FILES)

Returns a list of modified permissions, without chmodding files.
Accepts only symbolic permission modes.

=head2 getlschmod(MODE,FILES)

Returns a list of modified permissions, without chmodding files.
Accepts only "ls" permission modes.

=head2 getmod(FILES)

Returns a list of the current mode of each file.

=head1 VARIABLES

=head2 $File::chmod::DEBUG

If set to a true value, it will report warnings, similar to those produced
by chmod() on your system.  Otherwise, the functions will not report errors.
Example: a file can not have file-locking and the set-gid bits on at the
same time.  If $File::chmod::DEBUG is true, the function will report an
error.  If not, you are not warned of the conflict.  It is set to 1 as
default.

=head2 $File::chmod::MASK

Contains the umask to apply to new file modes when using getsymchmod().  This
defaults to the return value of umask() at compile time.  Is only applied if
$UMASK is true.

=head2 $File::chmod::UMASK

This is a boolean which tells getsymchmod() whether or not to apply the umask
found in $MASK.  It defaults to true.

=for test_synopsis my ( @files );

=head1 PORTING

This is only good on Unix-like boxes.  I would like people to help me work on
L<File::chmod> for any OS that deserves it.  If you would like to help, please
email me (address below) with the OS and any information you might have on how
chmod() should work on it; if you don't have any specific information, but
would still like to help, hey, that's good too.  I have the following
information (from L</perlport>):

=over 4

=item Win32

Only good for changing "owner" read-write access, "group", and "other" bits
are meaningless.  I<NOTE: Win32::File and Win32::FileSecurity already do
this.  I do not currently see a need to port File::chmod.>

=item MacOS

Only limited meaning. Disabling/enabling write permission is mapped to
locking/unlocking the file.

=item RISC OS

Only good for changing "owner" and "other" read-write access.

=back

=head1 SEE ALSO

  Stat::lsMode (by Mark-James Dominus, CPAN ID: MJD)
  chmod(1) manpage
  perldoc -f chmod
  perldoc -f stat

=for Pod::Coverage clear
determine_mode
g_not
g_or
l_not
l_or
mode
o_not
o_or
r_not
r_or
s_not
s_or
t_not
t_or
u_not
u_or
w_not
w_or
x_not
x_or

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/xenoterracide/file-chmod/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 CONTRIBUTORS

=for stopwords David Steinbrunner Slaven Rezic Steve Throckmorton Tim

=over 4

=item *

David Steinbrunner <dsteinbrunner@pobox.com>

=item *

Slaven Rezic <slaven@rezic.de>

=item *

Steve Throckmorton <arrestee@gmail.com>

=item *

Tim <oylenshpeegul@gmail.com>

=back

=head1 AUTHORS

=over 4

=item *

Jeff Pinyan <japhy.734+CPAN@gmail.com>

=item *

Caleb Cushing <xenoterracide@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Caleb Cushing and Jeff Pinyan.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
