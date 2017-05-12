#
# $Id: Ptrace.pm,v 0.5 2015/01/14 23:59:24 dankogai Exp dankogai $
#
package FreeBSD::i386::Ptrace;
use 5.008001;
use strict;
use warnings;
our $VERSION = sprintf "%d.%02d", q$Revision: 0.5 $ =~ /(\d+)/g;
require Exporter;
our @ISA = qw/Exporter/;

# XXX should be auto-generated like Syscall.pm

our @EXPORT = qw(
  ptrace pt_trace_me pt_attach pt_detach pt_kill
  pt_syscall pt_to_sce pt_to_scx
  pt_getcall pt_setcall pt_getregs pt_setregs pt_read pt_write
  pt_peekstr pt_pokestr
  PT_TRACE_ME
  PT_READ_I
  PT_READ_D
  PT_READ_U
  PT_WRITE_I
  PT_WRITE_D
  PT_WRITE_U
  PT_CONTINUE
  PT_KILL
  PT_STEP
  PT_ATTACH
  PT_DETACH
  PT_IO
  PT_LWPINFO
  PT_GETNUMLWPS
  PT_GETLWPLIST
  PT_CLEARSTEP
  PT_SETSTEP
  PT_SUSPEND
  PT_RESUME
  PT_TO_SCE
  PT_TO_SCX
  PT_SYSCALL
  PT_GETREGS
  PT_SETREGS
  PT_GETFPREGS
  PT_SETFPREGS
  PT_GETDBREGS
  PT_SETDBREGS
  PT_FIRSTMACH
);
our %EXPORT_TAGS = ( 'all' => [qw()] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

require XSLoader;
XSLoader::load( 'FreeBSD::i386::Ptrace', $VERSION );

# Preloaded methods go here.
use constant {
    PT_TRACE_ME   => 0,
    PT_READ_I     => 1,
    PT_READ_D     => 2,
    PT_READ_U     => 3,
    PT_WRITE_I    => 4,
    PT_WRITE_D    => 5,
    PT_WRITE_U    => 6,
    PT_CONTINUE   => 7,
    PT_KILL       => 8,
    PT_STEP       => 9,
    PT_ATTACH     => 10,
    PT_DETACH     => 11,
    PT_IO         => 12,
    PT_LWPINFO    => 13,
    PT_GETNUMLWPS => 14,
    PT_GETLWPLIST => 15,
    PT_CLEARSTEP  => 16,
    PT_SETSTEP    => 17,
    PT_SUSPEND    => 18,
    PT_RESUME     => 19,
    PT_TO_SCE     => 20,
    PT_TO_SCX     => 21,
    PT_SYSCALL    => 22,
    PT_GETREGS    => 33,
    PT_SETREGS    => 34,
    PT_GETFPREGS  => 35,
    PT_SETFPREGS  => 36,
    PT_GETDBREGS  => 37,
    PT_SETDBREGS  => 38,
    PT_FIRSTMACH  => 64,
};

use FreeBSD::i386::Ptrace::Syscall;
no warnings 'once';

use Class::Struct 'FreeBSD::i386::Struct::Regs' => [
    fs     => '$',
    es     => '$',
    ds     => '$',
    edi    => '$',
    esi    => '$',
    ebp    => '$',
    isp    => '$',
    ebx    => '$',
    edx    => '$',
    ecx    => '$',
    eax    => '$',
    trapno => '$',
    err    => '$',
    eip    => '$',
    cs     => '$',
    eflags => '$',
    esp    => '$',
    ss     => '$',
    gs     => '$',
];

*ptrace = \&pt_ptrace;
#*syscall = \&pt_syscall;
#*getcall = \&pt_getcall;

sub pt_trace_me() { ptrace(PT_TRACE_ME, 0,    0,  0) }
sub pt_attach($)  { ptrace(PT_ATTACH,   $_[0], 0, 0) }
sub pt_detach($)  { ptrace(PT_DETACH,   $_[0], 0, 0) }
sub pt_kill($)    { ptrace(PT_KILL,     $_[0], 0, 0) }

sub pt_syscall($) { ptrace(PT_SYSCALL,  $_[0], 1, 0) }
sub pt_to_sce($)  { ptrace(PT_TO_SCE,   $_[0], 1, 0) }
sub pt_to_scx($)  { ptrace(PT_TO_SCX,   $_[0], 1, 0) }

sub pt_read($$)   { ptrace(PT_READ_D,  $_[0], $_[1], 0) }
sub pt_write($$$) { ptrace(PT_WRITE_D, $_[0], $_[1], $_[2]) }

sub pt_getregs{ bless [ xs_getregs(shift) ] => 'FreeBSD::i386::Struct::Regs' }
sub pt_setregs{ xs_setregs($_[0], @{$_[1]}) };

sub pt_getcall($) { xs_getcall($_[0]) }
sub pt_setcall($$){ xs_setcall($_[0], $_[1]) }

sub pt_peekstr{
    my ($pid, $addr) = @_;
    my $str = '';
    while(1){
	my $int =  ptrace(PT_READ_D, $pid, $addr, 0);
	for my $c (unpack("C*", pack "I", $int)){
	    return $str unless $c;
	    $str .= chr $c
	}
	$addr += 4;
    }
}

sub pt_pokestr{
    my ($pid, $addr, $str) = @_;
    # special case: write 0 on empty string;
    return ptrace(PT_WRITE_D, $pid, $addr, 0) if !length($str);
    my $dst = pt_peekstr($pid, $addr);
    if (length($dst) < length($str)){
	substr($str, 0, length($dst), '');
    }
    while(my $q = substr($str, 0, 4, '')){
	my $int = 0;
	for my $c (reverse unpack "C*", $q){
	    $int = ($int << 8) + $c;
	}
	ptrace(PT_WRITE_D, $pid, $addr, $int);
        $addr += 4;
    }
}

1;
__END__

=head1 NAME

FreeBSD::i386::Ptrace - Ptrace for FreeBSD-i386

=head1 VERSION

$Id: Ptrace.pm,v 0.5 2015/01/14 23:59:24 dankogai Exp dankogai $

=head1 SYNOPSIS

  # simple strace in perl
  use strict;
  use warnings;
  use FreeBSD::i386::Ptrace;
  use FreeBSD::i386::Ptrace::Syscall;
  die "$0 prog args ..." unless @ARGV;
  my $pid = fork();
  die "fork failed:$!" if !defined($pid);
  if ( $pid == 0 ) {    # son
    pt_trace_me;
    exec @ARGV;
  }
  else {                # mom
    wait;               # for exec;
    my $count = 0;
    while ( pt_to_sce($pid) == 0 ) {
        last if wait == -1;
        my $call = pt_getcall($pid);
        pt_to_scx($pid);
        wait;
        my $retval = pt_getcall($pid);
        my $name = $SYS{$call} || 'unknown';
        last if $name eq 'exit'; # Needed for perl 5.18 and up
        print "$name() = $retval\n";
        $count++;
    }
    warn "$count system calls issued\n";
  }

=head1 EXPORT

C<ptrace>, C<pt_trace_me>, C<pt_attach>, C<pt_detach>,
C<pt_syscall>, C<pt_to_sce> C<pt_to_scx>
C<pt_getcall>,C<pt_setcall>. C<pt_getregs>, C<pt_setregs>
C<pt_read>, C<pt_write>,  C<pt_peekstr>, C<pt_pokestr>
C<pt_kill> and PT_* constants.

for C<%SYS>, use <FreeBSD::i386::Ptrace::Syscall>.

=head1 FUNCTIONS

=over 2

=item ptrace($request, $pid, $addr, $data)

A thin wrapper to L<ptrace/2>.

     #include <sys/types.h>
     #include <sys/ptrace.h>
     int
     ptrace(int request, pid_t pid, caddr_t addr, int data);

All arguments are integer from perl.

=item pt_trace_me()

Shortand for C<ptrace(PT_TRACE_ME, 0, 0, 0)>.

=item pt_attach($pid)

Shortand for C<ptrace(PT_ATTACH, pid, 0, 0)>.

=item pt_detach($pid)

Shortand for C<ptrace(PT_DETACH, pid, 0, 0)>.

=item pt_to_sce($pid)

Shortand for C<ptrace(PT_TO_SCE, pid, 0, 0)>.

Looks like SCE stands for "System Call Entry".

=item pt_to_scx($pid)

Shortand for C<ptrace(PT_TO_SCX, pid, 0, 0)>.

Looks like SCE stands for "System Call eXit".

=item pt_syscall($pid)

Shortand for C<ptrace(PT_SYSCALL, pid, 1, 0)>.  Unlike Linux the 3rd argument must be 1 or it loops infinitely.

Note PT_SYSCALL is invoked both on entry to and return from the system
call.  See L</SYNOPSIS> to see how to switch between them.

=item pt_getcall($pid)

Returns the value of EAX register which holds the system call NUMBER
on entry and the return value on return.

To get the name of system call you can import C<FreeBSD::i386::Ptrace::Syscall> and use C<%SYS>.

  my $call = pt_getcall(pid);
  my $name = %SYS{$call};

=item pt_setcall($pid, $value)

Sets the value of EAX register to $value.  Returns status.

CAVEAT: does not seem to work immidiately after pt_to_sce.  In other
words, you cannot alter system call that way!

=item pt_kill($pid)

Shortand for C<ptrace(PT_KILL, $pid, 0, 0>;
C<ptrace>, C<pt_trace_me>, C<pt_attach>, C<pt_detach>, C<pt_syscall>
C<pt_getcall> C<pt_kill> and PT_* constants.

CAVEAT: You CANNOT prevent the system call from being invoked with
this.  pt_to_sce does stop BEFORE the invocation.  But the signal is
sent AFTER tha system call so the process stops AFTER the invocation.
There seems no way to block the call.

  while ( pt_to_sce($pid) == 0 ) {
      last if wait == -1;
      my $call = pt_getcall($pid);
      my $name = $SYS{$call} || 'unknown';
      last if $name eq 'exit'; # Needed for perl 5.18 and up
      next if !$banned{ $name };
      pt_kill($pid); # happens AFTER the system call.
      die "SYS_$SYS{$call}\n";
  }
  alarm 0;

As for C<fork>, pt_kill only kills the parent.  Strangely replacing
pt_kill with C<ptrace(PT_CONTINUE, $pid, 0, 9)> kills the child as
well in which case core is dumped.

=item pt_getregs($pid)

Gets the register values.  Returns FreeBSD::i386::Struct::Regs object
That object allows OO access to te register.  Here is an example.

  my $regs = pt_getregs($pid);
  warn $regs->eax;

=item pt_setregs($pid, $reg)

Sets the register value to $reg where $reg is a 
FreeBSD::i386::Struct::Regs object.  The code below alters the value
of the EAX register.

  my $regs = pt_getregs($pid);
  $regs->eax(0);
  $status = pt_setregs($pid, $regs); # -1 on error

=item pt_read($pid, $addr)

Does ptrace(PT_READ_D, $pid, $addr, 0).  The code below reads the
value of the first argument of the stack.

  my $regs = pt_getregs($pid);
  my $st0  = pt_read($pid, $regs->eap + 4);
  my $st1  = pt_read($pid, $regs->eap + 8);
  # ....

=item pt_write($pid, $addr, $data)

Writes one 32 bit value in $data to $addr

  my $regs = pt_getregs($pid);
  # place null pointer to the first argument.
  my $status = pt_read($pid, $regs->eap + 4, 0);

=item pt_peekstr($pid, $addr)

Treats $addr as a string pointer and reads its content.  Be careful
when you use this.

  my $regs = pt_getregs($pid);
  my $str  = pt_peekstr($pid, $regs->eap + 4);

=item pt_pokestr($pid, $addr, $string)

Writes $string to the string pointer $addr.  If the $string is longer
than the original string, the string is truncated before copied.

  my $regs = pt_getregs($pid);
  # place null pointer to the first argument.
  my $status = pt_read($pid, $regs->eap + 4, 0);

=back

=head1 AUTHOR

Dan Kogai, C<< <dankogai at dan.co.jp> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-freebsd-i386-ptrace at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=FreeBSD-i386-Ptrace>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc FreeBSD::i386::Ptrace

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=FreeBSD-i386-Ptrace>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/FreeBSD-i386-Ptrace>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/FreeBSD-i386-Ptrace>

=item * Search CPAN

L<http://search.cpan.org/dist/FreeBSD-i386-Ptrace>

=back

=head1 ACKNOWLEDGEMENTS

L<Sys::Ptrace>


=head1 COPYRIGHT & LICENSE

Copyright 2009-2015 Dan Kogai, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
