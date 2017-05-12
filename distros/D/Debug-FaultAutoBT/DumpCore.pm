package Debug::DumpCore;

use 5.00503;

use strict;
#use warnings;

use Debug::FaultAutoBT (); # The C/XS code is in that module's .so object

$Debug::DumpCore::VERSION = '0.01';

1;
__END__

=head1 NAME

Debug::DumpCore - Generate a SegFault

=head1 SYNOPSIS

  use Debug::DumpCore;
  Debug::DumpCore::segv();

=head1 DESCRIPTION

This module implements a buggy C function which tries to dereference a
NULL pointer, which generates a SEGFAULT. It is used to test the
C<Debug::FaultAutoBT> module that attempts to automatically generate a
backtrace when some fatal signal is delivered, without needing the
core file.

Notice that you could use Perl's C<CORE::dump> to achieve the same
goal, but dump()'s backtrace is not very useful for teaching purposes.
C<Debug::DumpCore::segv()> calls another proper C function which
finally calls a buggy C function, which causes a SEGFAULT. So you get
a long trace. For example this is the backtrace generated on my
machine:

  #0  0x402b979b in crash_now_for_real (
      suicide_message=0x402ba040 "Cannot stand this life anymore")
      at DumpCore.xs:246
  #1  0x402b97bd in crash_now (
      suicide_message=0x402ba040 "Cannot stand this life anymore",
      attempt_num=42) at FaultAutoBT.xs:253
  #2  0x402b983e in XS_Debug__DumpCore_segv (cv=0x81751e4)
      at FaultAutoBT.xs:262
  #3  0x400851ec in Perl_pp_entersub ()
     from /usr/lib/perl5/5.6.1/i386-linux/CORE/libperl.so

And the corresponding C code around line 246 is:

   7:  crash_now_for_real(char *suicide_message)
   8:  {
   9:      int *p = NULL;
  10:      printf("%d", *p); /* cause a segfault */

=head1 EXPORT

None.

=head1 AUTHOR

Stas Bekman E<lt>stas@stason.orgE<gt>

=head1 SEE ALSO

perl(3), C<Debug::FaultAutoBT(3)>.

=cut
