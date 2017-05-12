package MPE::Spoonfeed;

require 5.005_62;
use strict;
use warnings;

require Exporter;
require MPE::Process;
use MPE::File;

our @ISA = qw(Exporter MPE::Process);

our %EXPORT_TAGS = ( 'all' => [ qw(
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

our $VERSION = '0.01';

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my @params;
  my @superparms;
  my $progname = shift;
  my %defaults = ( autocmd => '', autoactivate => 0, loadflag => 1);

  if (defined $_[0] && ref($_[0]) eq 'HASH') {
    @params = %{$_[0]};
  } else {
    @params = @_;
  }
  while (my $nextparm = shift @params) {
    my $nextparmval = shift @params;
    $nextparm =~ s/^-//;
    if (defined $defaults{lc $nextparm}) {
      $defaults{lc $nextparm} = $nextparmval;
    } else {
      push @superparms, $nextparm, $nextparmval;
    }
  }
  my $msgfilename = sprintf "T%03d%04d.PUB.SYS", 
     $$ % 1000, int(rand(10000)); 
  my $msgfile = MPE::File->new(
     "$msgfilename,new;temp;rec=-32000,,v,ascii;msg");
  if (!defined($msgfile)) {
    print STDERR "Error creating msg file $msgfilename: $MPE_error\n";
    return undef;
  }
  $msgfile->fclose(0,0);
  system("callci 'file $msgfilename,oldtemp;multi;shr;del'");
  $msgfile = MPE::File->new("$msgfilename;acc=append");
  if (!defined($msgfile)) {
    print STDERR "Error opening msg file $msgfilename: $MPE_error\n";
    return undef;
  }
  my $self  = $class->SUPER::new($progname, 
                        @superparms, 
                        STDIN => "*$msgfilename", 
                        loadflag => $defaults{loadflag});
  system("callci 'reset $msgfilename'");
  if (!defined($self) || $self == 0) {
    print STDERR "Error on CreateProcess: $MPE::Process::CreateStatus\n";
    return undef;
  }

  @{$self}{keys %defaults} = values %defaults;
  $$self{msgfile} = $msgfile;
  return bless $self, $class;
}

sub DESTROY {
  my $self = shift;
  $$self{msgfile}->fclose(0,0);
  $self->SUPER::DESTROY();
}

sub cmds {
  my $self = shift;
  my $msgfile = $$self{msgfile};
  for (@_) {
    if (!$msgfile->writerec($_)) {
      die "Error writing to msgfile: $MPE_error\n";
    }
  }
  if ($$self{autocmd}) {
    if (!$msgfile->writerec($$self{autocmd})) {
      die "Error writing to msgfile: $MPE_error\n";
    }
  }
  if ($$self{autoactivate}) {
    $self->activate(2);
  }
}

sub suppressboguswarning {
   print STDERR "Error on CreateProcess: $MPE::Process::CreateStatus\n";
}

sub cmdsactivate {
  my $self = shift;
  my $msgfile = $$self{msgfile};
  for (@_) {
    if (!$msgfile->writerec($_)) {
      die "Error writing to msgfile: $MPE_error\n";
    }
  }
  if ($$self{autocmd}) {
    if (!$msgfile->writerec($$self{autocmd})) {
      die "Error writing to msgfile: $MPE_error\n";
    }
  }
  $self->activate(2);
}


1;
__END__

=head1 NAME

MPE::Spoonfeed - Perl extension for "spoonfeeding" commands through
                 a message file to MPE programs run as child process

=head1 SYNOPSIS

  use MPE::Spoonfeed;

  my $ciproc = MPE::Spoonfeed->new("CI.PUB.SYS", activate=>0)
    or die "Spoonfeed failed: $MPE::Process::CreateStatus\n";

  $ciproc->cmds("ECHO HI", "LISTFILE ./S@,2")

  # Just an example; there are easier ways to run CI commands!
 


  # QEDIT
  my $qproc =  MPE::Spoonfeed->new("QEDIT.PUB.ROBELLE")
    or die "Spoonfeed failed: $MPE::Process::CreateStatus\n";

  $qproc->cmds("TEXT TESTTEXT", "change 'LARRY'DARRYL' @");
  $qproc->cmds("KEEP ,Y");
  $qproc->cmdsactivate("EXIT") or die "some error message\n";


  # MPEX
  my $mpex =  MPE::Spoonfeed->new("MAIN.PUB.VESOFT",
                                   parm => 3,
                                   autoactivate =>1,
                                   autocmd => "EXIT")
    or die "Spoonfeed failed: $MPE::Process::CreateStatus\n";

  $mpex->cmds("PURGE @.DATA(ACCDATE<TODAY-90);YES");


=head1 DESCRIPTION

This module is designed to make it easy to create MPE subprocesses
and pipe commands to them via a message file.  This is most useful
for MPE programs that support the convention of reactivating the
parent process instead of exiting.  Among the programs that do this
are MPEX, Suprtool, QEDIT, DBGeneral, and Librarian/3000.  There are
others, but these are the ones that I can think of right now.

The module depends on MPE::File and MPE::Process.  You probably will
also want MPE::CIvar.

For almost any MPE program that reads commands (or other input) from
STDIN--such as CI.PUB.SYS--you can do this:
   my $proc = MPE::Spoonfeed->new("CI.PUB.SYS", activate=>0)
      or die "some error message";
Then you can send commands to the process this way:
   $proc->cmds("echo Hi There!");

This is very similar to opening a pipe to a child process in a
POSIX program:
  open(CIPROC, "/SYS/PUB/CI") or die "some error message";
  print CIPROC "echo Hi There!\n";
But this doesn't actually work with CI.PUB.SYS

Note that when the call
   $proc->cmds("echo Hi There!");
returns, you do NOT know that the command has yet been executed.  The
child process is running asychronously, waiting for input on the
message file.  Therefore, you cannot immediately check (e.g.) a JCW
to see if the command succeeded.

However, for a program like MPEX, you can run it like this:
   my $proc = MPE::Spoonfeed->new("MAIN.PUB.VESOFT")
      or die "some error message";
   $proc->cmds("echo Hi There!");
   $proc->cmds("EXIT");
   $proc->activate(2);
When you call activate(2), your program (Perl) activates the child
process and then waits.  When MPEX process the EXIT command, it
reactivates the father process (Perl, in this case) and then waits.
That way you do know that MPEX has processed the commands and you can
check JCWs or CI variables to see if it succeeded.

You can actually use the same approach with CI, but when it gets to
the EXIT command, it actually does terminate.  This is really no
different from writing commands to a file, then running CI with that
file as input.

MPEX remains dormant and you can send more commands, maintaining the
state between sets of commands.  You also get the advantage of
avoiding the start-up cost of a new process.

You can combine these commands
   $proc->cmds("echo Hi There!");
   $proc->cmds("EXIT");
   $proc->activate(2);
like this:
   $proc->cmds("echo Hi There!");
   $proc->cmdsactivate("EXIT");
or this:
   $proc->cmdsactivate("echo Hi There!", "EXIT");

You can also set 'autocmd' and 'autoactivate' flags when you create
your process:
   my $proc = MPE::Spoonfeed->new("MAIN.PUB.VESOFT", 
                                   autoactivate => 1,
                                   autocmd => 'EXIT')
      or die "some error message";

In this case, a command sequence like this:
  $proc->cmds("echo 1", "echo 2", "echo 3");
  $proc->cmds("echo 4", "echo 5");
is processed like this:
  $proc->cmds("echo 1");
  $proc->cmds("echo 2");
  $proc->cmds("echo 3");
  $proc->cmds("EXIT");
  $proc->activate(2);
  $proc->cmds("echo 4");
  $proc->cmds("echo 5");
  $proc->cmds("EXIT");
  $proc->activate(2);

With MPEX, that's very convenient.  Be careful with some other
programs, though.  With Suprtool, for example, you only want an
"EXIT" after a complete set of commands. The "EXIT" command will
execute the current task.  Suprtool does have an "EXIT SUSPEND" (ES)
command which will just suspend. (There is also an MPE::Suprtool
module which is simpler to use than Spoonfeed in this case.)  QEDIT
closes its current workfile when you "EXIT".

MPE::Spoonfeed is a subclass of MPE::Process and you can specify
any of the Process options (info, parm, etc.) when you are creating a 
Spoonfeed object.
   my $proc = MPE::Spoonfeed->new("MAIN.PUB.VESOFT", 
                                   parm => 1,
                                   stdout => "SAVEOUT",
                                   autoactivate => 1,
                                   autocmd => 'EXIT')
Every option except "stdin", that is, which Spoonfeed defines itself.
Spoonfeed also sets a default loadflag of "1", which guarantees that
your program will be reactivated if the subprocess exits without
reactivating the parent.  You can override this, but you should
always make sure that your load flag has the low bit set to 1.


A special note about JCWs and CI variables:  if you want to check a JCW
to see if a subprocess succeeded, say MPEXNUMSUCCEEDED or CIERROR,
you I<cannot> check $ENV{MPEXNUMSUCCEEDED} or $ENV{CIERROR}.  Although
it is true that when a POSIX program is run from a non-POSIX program, all
the JCWs and CI variables are imported into the environment, any changes
made after that will not be reflected in the environment.  What you need
to do is:
  use MPE::CIvar ':all';
Then you can check and set the value of CI vars with
$CIVAR{MPEXNUMSUCCEEDED} and $CIVAR{CIERROR}.  For conservative
programming, you should set the value of the variable in question
I<before> you execute your commands and check afterwards to see if it
has been changed.  Otherwise you may see the value from a previous
command.

=head2 EXPORT

None by default.


=head1 AUTHOR

Ken Hirsch E<lt>F<kenhirsch@myself.com>E<gt>

=head1 SEE ALSO

perl(1).

L<MPE::Process>

L<MPE::File>

L<MPE::CIvar>

=cut
