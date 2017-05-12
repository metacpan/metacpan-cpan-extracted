package Mail::Qmail::Queue::Error;
our $VERSION = 0.02;
#
# Copyright 2006 Scott Gifford
#
# This library is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

use warnings;
use strict;

use base 'Exporter';

our %EXPORT_TAGS = (
		    errcodes => [qw(
 QQ_EXIT_ADDR_TOO_LONG QQ_EXIT_REFUSED QQ_EXIT_NOMEM QQ_EXIT_TIMEOUT
 QQ_EXIT_WRITEERR QQ_EXIT_READERR QQ_EXIT_BADCONF QQ_EXIT_NETERR
 QQ_EXIT_BADQHOME QQ_EXIT_BADQUEUEDIR QQ_EXIT_BADQUEUEPID
 QQ_EXIT_BADQUEUEMESS QQ_EXIT_BADQUEUEINTD QQ_EXIT_BADQUEUETODO
 QQ_EXIT_TEMPREFUSE QQ_EXIT_CONNTIMEOUT QQ_EXIT_NETREJECT
 QQ_EXIT_NETFAIL QQ_EXIT_BUG QQ_EXIT_BADENVELOPE
				   )],
		    fail => [qw(tempfail permfail qfail)],
		    test => [qw(is_tempfail is_permfail)],
		    );

our @EXPORT_OK = (map { @$_} values %EXPORT_TAGS);

use Carp;

=head1 NAME

Mail::Qmail::Queue::Error - Error handling for programs which emulate or use qmail-queue. 

=head1 SYNOPSIS

  use Mail::Qmail::Queue::Error qw(:errcodes :fail);

  print "blah\n"
    or tempfail QQ_EXIT_WRITEERR,"Write error: $!\n";

  if (has_virus($body)) {
    permfail QQ_EXIT_REFUSED,"Message refused: it has a virus!!\n";
  }

  qfail $exit_status,"qmail-queue exited $exit_status\n";

=head1 DESCRIPTION

C<Mail::Qmail::Queue::Error> is designed to simplify error handling
for a program which emulates or uses a program implementing the
L<qmail-queue(8)|qmail-queue(8)> interface.  It declares constants for
a variety of permanent and temporary error codes, and provides
shorthand methods similar to C<die> that return an appropriate error
code.  It also provides some methods to look at an error code returned
by C<qmail-queue> and determine whether it is temporary or permanent.

=head2 CONSTANTS

These constants are defined in L<qmail-queue(8)>.  They are mostly
self-explanatory.

=head3 Permanent Errors

=over 4

=item QQ_EXIT_ADDR_TOO_LONG

=cut

use constant QQ_EXIT_ADDR_TOO_LONG => 11;

=item QQ_EXIT_REFUSED

=cut

use constant QQ_EXIT_REFUSED => 31;

=back

=head3 Temporary Errors

=over 4

=item QQ_EXIT_NOMEM

=cut

use constant QQ_EXIT_NOMEM => 51;

=item QQ_EXIT_TIMEOUT

=cut

use constant QQ_EXIT_TIMEOUT => 52;

=item QQ_EXIT_WRITEERR

=cut

use constant QQ_EXIT_WRITEERR => 53;

=item QQ_EXIT_READERR

=cut

use constant QQ_EXIT_READERR => 54;

=item QQ_EXIT_BADCONF

=cut

use constant QQ_EXIT_BADCONF => 55;

=item QQ_EXIT_NETERR

=cut

use constant QQ_EXIT_NETERR => 56;

=item QQ_EXIT_BADQHOME

=cut

use constant QQ_EXIT_BADQHOME => 61;

=item QQ_EXIT_BADQUEUEDIR

=cut

use constant QQ_EXIT_BADQUEUEDIR => 62;

=item QQ_EXIT_BADQUEUEPID

=cut

use constant QQ_EXIT_BADQUEUEPID => 63;

=item QQ_EXIT_BADQUEUEMESS

=cut

use constant QQ_EXIT_BADQUEUEMESS => 64;

=item QQ_EXIT_BADQUEUEINTD

=cut

use constant QQ_EXIT_BADQUEUEINTD => 65;

=item QQ_EXIT_BADQUEUETODO

=cut

use constant QQ_EXIT_BADQUEUETODO => 66;

=item QQ_EXIT_TEMPREFUSE

=cut

use constant QQ_EXIT_TEMPREFUSE => 71;

=item QQ_EXIT_CONNTIMEOUT

=cut

use constant QQ_EXIT_CONNTIMEOUT => 72;

=item QQ_EXIT_NETREJECT

=cut

use constant QQ_EXIT_NETREJECT => 73;

=item QQ_EXIT_NETFAIL

=cut

use constant QQ_EXIT_NETFAIL => 74;

=item QQ_EXIT_BUG

=cut

use constant QQ_EXIT_BUG => 81;

=item QQ_EXIT_BADENVELOPE

=cut

use constant QQ_EXIT_BADENVELOPE => 91;

=back

=head2 FUNCTIONS

=over 4

=item tempfail ( [$failcode,] @message )

Exit with a temporary failure code, or C<die> if in an C<eval>.  If
the first argument is numeric, or if the message starts with a number,
that will be used as the exit code.  Otherwise, the temporary failure
code C<QQ_EXIT_BUG> will be used.

Note that no checking of the failure code is done; if you pass a code
that does not indicate temporary failure, it will be used as is.

=cut

sub tempfail(@)
{
    unshift(@_,QQ_EXIT_BUG);
    goto &_fail;
}

=item permfail ( [$failcode,] @message )

Exit with a permanent failure code, or C<die> if in an C<eval>.  If
the first argument is numeric, that will be used as the exit code.
Otherwise, the permanent failure code C<QQ_EXIT_REFUSED> will be used.

Note that no checking of the failure code is done; if you pass a code
that does not indicate permanent failure, it will be used as is.

=cut

sub permfail(@)
{
    
    unshift(@_,QQ_EXIT_REFUSED);
    goto &_fail;
}

=item qfail ( [$failcode,] @message )

Exit with a failure code, or C<die> if in an C<eval>.  If the first
argument is numeric, that will be used as the exit code.  Otherwise,
the temporary failure code C<QQ_EXIT_BUG> will be used.

=cut

sub qfail(@)
{
    goto &tempfail;
}

=item is_tempfail ( $exit_value )

Test if the provided value is a temporary exit status.

=cut

sub is_tempfail
{
    return !is_permfail(@_);
}

=item is_permfail

Test if the provided value is a permanent exit status.

=cut

sub is_permfail
{
    return ($_[0] >= 11 and $_[0] <= 40);
}

sub _fail(@)
{
    my $default_ec = shift;
    if ($^S)
    {
	# Eval
	die @_;
    }
    my $ec = ($_[0] =~ /^\d+$/) ? shift : $default_ec;

    carp @_;
    exit($ec);
}

=back

=head1 SEE ALSO

L<qmail-queue(8)>, L<Mail::Qmail::Queue::Message>,
L<Mail::Qmail::Queue::Receive::Body>,
L<Mail::Qmail::Queue::Receive::Envelope>, L<Mail::Qmail::Queue::Send>.

=head1 COPYRIGHT

Copyright 2006 Scott Gifford.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
