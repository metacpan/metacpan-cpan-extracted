package Linux::Personality;

use strict;
use warnings;
use Carp;

require Exporter;
use AutoLoader;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Linux::Personality ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.

our @EXPORT         = ();
our %EXPORT_TAGS    = (
                       'funcs'  => [ qw/ personality / ],
                       'consts' => [ qw/ ADDR_LIMIT_32BIT
                                         ADDR_LIMIT_3GB
                                         ADDR_NO_RANDOMIZE
                                         MMAP_PAGE_ZERO
                                         PER_BSD
                                         PER_HPUX
                                         PER_IRIX32
                                         PER_IRIX64
                                         PER_IRIXN32
                                         PER_ISCR4
                                         PER_LINUX
                                         PER_LINUX32
                                         PER_LINUX32_3GB
                                         PER_LINUX_32BIT
                                         PER_MASK
                                         PER_OSF4
                                         PER_OSR5
                                         PER_RISCOS
                                         PER_SCOSVR3
                                         PER_SOLARIS
                                         PER_SUNOS
                                         PER_SVR3
                                         PER_SVR4
                                         PER_UW7
                                         PER_WYSEV386
                                         PER_XENIX
                                         SHORT_INODE
                                         STICKY_TIMEOUTS
                                         WHOLE_SECONDS
                                       / ],
                                         # ADDR_COMPAT_LAYOUT # not in 2.6.28
                                         # READ_IMPLIES_EXEC  # not in 2.6.28
                      );
our @EXPORT_OK      = map { @$_ } values %EXPORT_TAGS;
$EXPORT_TAGS{'all'} = [ @EXPORT_OK ];

our $VERSION = '0.01';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&Linux::Personality::constant not defined" if $constname eq 'constant';
    my ($error, $val) = constant($constname);
    if ($error) { croak $error; }
    {
	no strict 'refs';
	# Fixed between 5.005_53 and 5.005_61
#XXX	if ($] >= 5.00561) {
#XXX	    *$AUTOLOAD = sub () { $val };
#XXX	}
#XXX	else {
	    *$AUTOLOAD = sub { $val };
#XXX	}
    }
    goto &$AUTOLOAD;
}

require XSLoader;
XSLoader::load('Linux::Personality', $VERSION);

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Linux::Personality - Perl interface to the personality(2) Linux system call.

=head1 SYNOPSIS

Common usage:

  use Linux::Personality qw/personality PER_LINUX32 /;
  print `uname -m`;                  # x86_64
  personality(PER_LINUX32);
  print `uname -m`;                  # i686

Use flags for bugs emulation:

  use Linux::Personality qw/personality
                            PER_LINUX32
                            ADDR_LIMIT_3GB
                            SHORT_INODE
                            MMAP_PAGE_ZERO /;
  personality(PER_LINUX32 | ADDR_LIMIT_3GB | SHORT_INODE | MMAP_PAGE_ZERO);

=head1 DESCRIPTION

You can use this for instance when running 32bit compiles started from
inside a Perl program in a 32bit chroot but running on a 64bit host
kernel. Without hints the compile tools get confused and try do do
64bit in the 32bit environment.

It's somewhat comparable to the C<setarch> (also known as C<linux32>)
utility. With C<personality> you can get similar effect inside a Perl
program.

From "man 2 personality":

 NAME
        personality - set the process execution domain
 
 SYNOPSIS
        #include <sys/personality.h>
        int personality(unsigned long persona);
 
 DESCRIPTION
        Linux supports different execution domains, or personalities,
        for each process.  Among other things, execution domains tell
        Linux how to map signal numbers into signal actions.  The
        execution domain system allows Linux to provide limited
        support for binaries compiled under other Unix-like operating
        systems.

        This function will return the current personality() when
        persona equals 0xffffffff.  Otherwise, it will make the
        execution domain referenced by persona the new execution
        domain of the calling process.
 
 RETURN VALUE
        On success, the previous persona is returned.  On error, -1 is
        returned, and errno is set appropriately.
 
 ERRORS
        EINVAL The kernel was unable to change the personality.
 
 CONFORMING TO
        personality() is Linux-specific and should not be used in
        programs intended to be portable.

=head2 EXPORT

None by default.

=head2 Exportable functions

  personality

=head2 Exportable constants

  ADDR_LIMIT_32BIT
  ADDR_LIMIT_3GB
  ADDR_NO_RANDOMIZE
  MMAP_PAGE_ZERO
  PER_BSD
  PER_HPUX
  PER_IRIX32
  PER_IRIX64
  PER_IRIXN32
  PER_ISCR4
  PER_LINUX
  PER_LINUX32
  PER_LINUX32_3GB
  PER_LINUX_32BIT
  PER_MASK
  PER_OSF4
  PER_OSR5
  PER_RISCOS
  PER_SCOSVR3
  PER_SOLARIS
  PER_SUNOS
  PER_SVR3
  PER_SVR4
  PER_UW7
  PER_WYSEV386
  PER_XENIX
  SHORT_INODE
  STICKY_TIMEOUTS
  WHOLE_SECONDS

=head1 SEE ALSO

 man 2 personality
 /usr/include/sys/personality.h

=head1 AUTHOR

Steffen Schwigon, C<< <ss5@renormalist.net> >>

=head1 CREDITS

Maik Hentsche C<< <maik.hentsche@amd.com> >> for having the problem in
the first place and digging the according solution.

Florian Ragwitz C<< <rafl@debian.org> >> for the usual Perl low-level
support.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Steffen Schwigon

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
