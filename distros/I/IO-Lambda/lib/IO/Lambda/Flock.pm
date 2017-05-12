# $Id: Flock.pm,v 1.8 2009/04/21 14:42:46 dk Exp $
package IO::Lambda::Flock;
use vars qw($DEBUG @ISA @EXPORT_OK);
@ISA = qw(Exporter);
@EXPORT_OK   = qw(flock);
%EXPORT_TAGS = ( all => \@EXPORT_OK);
$DEBUG = $IO::Lambda::DEBUG{flock} || 0;

use strict;
use warnings;
use Fcntl ':flock';
use IO::Lambda qw(:all :dev);
use IO::Lambda::Poll qw(poll_event);

sub poll_flock
{
	my ( $expired, $fh, $shared) = @_;
	if ( CORE::flock( $fh, LOCK_NB | ($shared ? LOCK_SH : LOCK_EX) )) {
		warn "flock $fh obtained\n" if $DEBUG;
		return 1, 1;
	}
	return 1, 0 if $expired;
	return 0;
}

sub flock(&)
{
	return this-> override_handler('flock', \&flock, shift)
		if this-> {override}->{flock};

	my $cb = _subname flock => shift;
	my ($fh, %opt) = context;
	my $deadline = exists($opt{timeout}) ? $opt{timeout} : $opt{deadline};

	poll_event(
		$cb, \&flock, \&poll_flock, 
		$deadline, $opt{frequency}, 
		$fh, $opt{shared}
	);
}


# The same code can be written way more elegant:
#
#	sub flock(&)
#	{
#		poller { 
#			my %opt = @_;
#			CORE::flock( 
#				$opt{fh}, 
#				LOCK_NB | ($opt{shared} ? LOCK_SH : LOCK_EX
#			);
#		}
#		-> call(context)
#		-> condition(shift, \&flock, 'flock')
#	}
#
#  but will require another calling style:
#
#	context fh => $fh, deadline => 5;
#	flock { ok }

1;

__DATA__

=pod

=head1 NAME

IO::Lambda::Flock - lambda-style file locking

=head1 DESCRIPTION

The module provides file locking interface for the lambda style,
implemented by using non-blocking, periodic polling of flock(2).

=head1 SYNOPSIS

    open LOCK, ">lock";
    lambda {
        # obtain the lock 
        context \*LOCK, timeout => 10;
        flock { die "can't obtain lock" unless shift }
        
        # while reading from handle
        context $handle;
        readable { ... }

        # and showing status 
        context 0.5;
        timeout { print '.'; again }
    };

=head1 API

=over

=item flock($filehandle, %options) -> ($lock_obtained = 1 | $timeout = 0)

Waits until the file lock is obtained or the timeout is expired. When successful,
the (shared or exclusive) lock on C<$filehandle> is acquired by C<flock($filehandle,
LOCK_NB)> call. Options:

=over

=item C<timeout> or C<deadline>

These two options are synonyms, both declare the moment when the lambda waiting
for the lock should give up. If undef, timeout never occurs.

=item shared

If set, C<LOCK_SH> is used, otherwise C<LOCK_EX>.

=item frequency

Defines how often the polling for the lock should occur. If left undefined,
polling occurs during idle time, when other events are dispatched.

=back

=back

=head1 SEE ALSO

L<Fcntl>, L<IO::Lambda::Poll>.

=head1 AUTHOR

Dmitry Karasik, E<lt>dmitry@karasik.eu.orgE<gt>.

=cut
