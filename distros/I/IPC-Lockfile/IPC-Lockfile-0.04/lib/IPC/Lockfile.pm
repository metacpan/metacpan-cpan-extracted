use strict;
use warnings;
package IPC::Lockfile;
$IPC::Lockfile::VERSION = '0.04';
# ABSTRACT: run only one instance of a program at a time using flock
use Fcntl qw(:flock);

# lexical filehandles dont work!
open our $LOCKFILE, '<', $0  or die "Unable to create the lockfile $0 $!\n";
flock $LOCKFILE, LOCK_EX|LOCK_NB or die "$0 is running!\n";


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IPC::Lockfile - run only one instance of a program at a time using flock

=head1 VERSION

version 0.04

=head1 SYNOPSIS

Just import the module:

    #!/usr/bin/env perl
    use IPC::Lockfile;

    ... # program code here

This will open a lock on the program file, avoiding the need for an external
lockfile. This elegant L<solution|http://perl.plover.com/yak/flock/samples/slide006.html> for lockfiles was proposed by Mark Jason Dominus.

=head1 DESCRIPTION

C<IPC::Lockfile> is a module for use with Perl programs when you only want one
instance of the script to run at a time. It uses C<flock> and should work if
run on an OS that supports C<flock> (e.g. Linux, BSD, OSX and Windows).

=head1 SEE ALSO

L<Sys::RunAlone> for a more flexible module that uses the same technique as C<IPC::Lockfile>

My PerlTricks.com L<article|http://perltricks.com/article/2/2015/11/4/Run-only-one-instance-of-a-program-at-a-time> about this solution.

L<IPC::Pidfile> for a PID-based solution that relies on signals and has a race
condition (not recommended).

=head1 AUTHOR

David Farrell <dfarrell@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by David Farrell.

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
