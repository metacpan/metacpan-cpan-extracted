package Linux::Unshare;

use 5.010000;
use strict;
use warnings;
use Carp;

require Exporter;
use AutoLoader;

our @ISA = qw(Exporter);

# This allows declaration	use Linux::Unshare ':all';
our %EXPORT_TAGS = ( 'clone' => [ qw(
	CLONE_THREAD CLONE_FS CLONE_SIGHAND CLONE_VM CLONE_FILES CLONE_SYSVSEM
	CLONE_CONTAINER CLONE_NEWNS CLONE_NEWUTS CLONE_NEWIPC CLONE_NEWNET
	CLONE_NEWPID CLONE_NEWUSER CLONE_NEWCGROUP
) ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'clone'} }, qw(unshare unshare_ns) );
our @EXPORT = qw( );

our $VERSION = '1.2';

sub AUTOLOAD {
    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&Linux::Unshare::constant not defined" if $constname eq 'constant';
    my ($error, $val) = constant($constname);
    if ($error) { croak $error; }
    {
        no strict 'refs';
        *$AUTOLOAD = sub { $val };
    }
    goto &$AUTOLOAD;
}

require XSLoader;
XSLoader::load('Linux::Unshare', $VERSION);

sub unshare_ns { return unshare(0x20000) ? 0 : -1; }

1;
__END__
=head1 NAME

Linux::Unshare - Perl interface for Linux unshare system call.

=head1 SYNOPSIS

  use Linux::Unshare qw(unshare :clone);

  # as root ...
  unshare(CLONE_NEWNS)
  # now your mounts will become private

  unshare(CLONE_NEWNET)
  # get a separate network namespace


=head1 DESCRIPTION

This trivial module provides an interface to the Linux unshare system call. It
also provides the CLONE_* constants that are used to specify which kind of
unsharing must be performed. Note that some of these are still not implemented
in the Linux kernel, and others are still experimental.

The unshare system call allows a process to 'unshare' part of the process
context which was originally shared using clone(2).

=head1 SEE ALSO

unshare(2) Linux man page.

=head1 AUTHOR

Boris Sukholitko, E<lt>boriss@gmail.comE<gt>
Marian Marinov, E<lt>hackman@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Boris Sukholitko
Copyright (C) 2014-2023 by Marian Marinov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
