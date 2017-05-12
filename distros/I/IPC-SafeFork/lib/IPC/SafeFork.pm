package IPC::SafeFork;

use 5.008008;
use strict;
use warnings;

use base qw( Exporter );
use POSIX qw(sigprocmask SIG_SETMASK);

our %EXPORT_TAGS = ( 'all' => [ qw(
    safe_fork fork
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw( safe_fork );

our $VERSION = '0.0100';

require XSLoader;
XSLoader::load('IPC::SafeFork', $VERSION);

our $MASKALL;

sub safe_fork ()
{
    return xs_fork();
}

*fork = \&safe_fork;

1;
__END__

=head1 NAME

IPC::SafeFork - Safe wrapper around fork

=head1 SYNOPSIS

    use IPC::SafeFork;
    my $pid = safe_fork();

    use IPC::SafeFork qw( fork );
    my $pid = fork();

=head1 DESCRIPTION

Fork is not signal safe in perl; due to a race condition a signal could be
delivered to both the parent and the child process.  This is because in
perl, signals set a flag that is verified when it is safe to do so.  This
flag is not reset in the child.

However, reseting the signal in the child will introduces a new race window;
if a signal arrives to the child between the fork and the reset, it will be
lost.  It would be nice to use sigprocmask(2) to close this window, but that
would mess with waitpid().

So it's up to you to decide: do you want more signals to the child (perl
built-in) or fewer signals (safe_fork).

=head1 FUNCTIONS

=head2 safe_fork

Forks the process and resets the signal flags in the child process.

=head2 fork

Same as L</safe_fork>.  Not exported by default.

=head2 TODO

=over 4

=item open "|-"

=item A way to flush all open file handles.

=back

=head2 EXPORT

L</safe_fork> by default.

L</fork> is also available.


=head1 SEE ALSO

This is the L<perlbug> of the problem
http://rt.perl.org/rt3//Public/Bug/Display.html?id=82580

=head1 AUTHOR

Philip Gwyn, E<lt>gwyn-at-cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Philip Gwyn

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
