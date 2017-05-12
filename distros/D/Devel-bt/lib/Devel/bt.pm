use strict;
use warnings;

package Devel::bt;
BEGIN {
  $Devel::bt::AUTHORITY = 'cpan:FLORA';
}
{
  $Devel::bt::VERSION = '0.06';
}
# ABSTRACT: Automatic gdb backtraces on errors


use XSLoader;
use Carp 'croak';
use File::Which 'which';

XSLoader::load(
    __PACKAGE__,
    # we need to be careful not to touch $VERSION at compile time, otherwise
    # DynaLoader will assume it's set and check against it, which will cause
    # fail when being run in the checkout without dzil having set the actual
    # $VERSION
    exists $Devel::bt::{VERSION} ? ${ $Devel::bt::{VERSION} } : (),
);

sub DB::DB { }

sub find_gdb { which 'gdb' }

sub import {
    my ($class, %args) = @_;

    my $gdb = exists $args{gdb} ? $args{gdb} : $class->find_gdb();
    croak 'Unable to locate gdb binary'
        unless defined $gdb && -x $gdb;

    register_segv_handler($gdb, $^X);
    return;
}

1;

__END__
=pod

=encoding utf-8

=head1 NAME

Devel::bt - Automatic gdb backtraces on errors

=head1 SYNOPSIS

    $ perl -d:bt -MB -e'(bless \(my $o = 0), q{B::SV})->REFCNT'
    #0  0x00007f9c3215ab0e in __libc_waitpid (pid=<value optimized out>, stat_loc=0x7fff4c5ffbe8, options=<value optimized out>) at ../sysdeps/unix/sysv/linux/waitpid.c:32
    #1  0x00007f9c319168c1 in backtrace () at bt.xs:129
    #2  0x00007f9c319168ec in sighandler (sig=11) at bt.xs:135
    #3  <signal handler called>
    #4  0x00007f9c316c8ccf in XS_B__SV_REFCNT (my_perl=0x151c010, cv=0x177bfb8) at B.c:3360
    #5  0x000000000057d5a0 in Perl_pp_entersub (my_perl=0x151c010) at pp_hot.c:2882
    #6  0x000000000051a331 in Perl_runops_debug (my_perl=0x151c010) at dump.c:2049
    #7  0x0000000000454ab0 in S_run_body (my_perl=0x151c010, oldscope=1) at perl.c:2308
    #8  0x0000000000453d78 in perl_run (my_perl=0x151c010) at perl.c:2233
    #9  0x00000000004230fd in main (argc=6, argv=0x7fff4c600788, env=0x7fff4c6007c0) at perlmain.c:117

=head1 DESCRIPTION

This module, when enabled, registers a handler for certain types of fatal
errors, like segmentation faults, and, once such an error occurs, prints a
debugger backtrace to standard output before exiting the program.

It is intended to be used to debug crashes in situations where running the
failing program directly under a debugger is not possible, for example when
trying to get more information from cpantesters or from users unfamiliar with
gdb.

=head1 HOW IT WORKS

When being imported, a signal handler for the following signals is registered:

=over 4

=item *

C<SIGILL>

=item *

C<SIGFPE>

=item *

C<SIGBUS>

=item *

C<SIGSEGV>

=item *

C<SIGTRAP>

=item *

C<SIGABRT>

=item *

C<SIGQUIT>

=back

Once the program causes an error that results in one of the above signals being
sent to it, the signal handler will be called, and fork off a process running
C<gdb> and generating a backtrace of the running program, which will then be
printed to standard output.

=head1 ACKNOWLEDGEMENTS

This software is based on parts of C<glib>, which is written by:

=over 4

=item *

Peter Mattis E<lt>petm@xcf.berkeley.eduE<gt>

=item *

Spencer Kimball E<lt>spencer@xcf.berkeley.eduE<gt>

=item *

Josh MacDonald E<lt>jmacd@xcf.berkeley.eduE<gt>

=item *

Shawn T. Amundson E<lt>amundson@gimp.orgE<gt>

=item *

Jeff Garzik E<lt>jgarzik@pobox.comE<gt>

=item *

Raja R Harinath E<lt>harinath@cs.umn.eduE<gt>

=item *

Tim Janik E<lt>timj@gtk.orgE<gt>

=item *

Elliot Lee E<lt>sopwith@redhat.comE<gt>

=item *

Tor Lillqvist E<lt>tml@iki.fiE<gt>

=item *

Paolo Molaro E<lt>lupus@debian.orgE<gt>

=item *

Havoc Pennington E<lt>hp@pobox.comE<gt>

=item *

Manish Singh E<lt>yosh@gimp.orgE<gt>

=item *

Owen Taylor E<lt>otaylor@gtk.orgE<gt>

=item *

Sebastian Wilhelmi E<lt>wilhelmi@ira.uka.deE<gt>

=item *

and others

=back

C<glib> is licensed under The GNU Lesser General Public License, Version 2.

=head1 AUTHOR

Florian Ragwitz <rafl@debian.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Florian Ragwitz.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut

