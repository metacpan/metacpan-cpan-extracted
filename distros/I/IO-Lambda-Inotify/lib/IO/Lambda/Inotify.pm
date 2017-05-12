package IO::Lambda::Inotify;

use strict;
use warnings;
use IO::Handle;
use IO::Lambda qw(:all :dev);
use Linux::Inotify2;
use base qw(Exporter);
our $VERSION = '1.01';
our @EXPORT_OK = qw(
	inotify
	inotify_server
	inotify_auto
	inotify_timeout
	inotify_plain
);
our %EXPORT_TAGS = ( all => [ qw(inotify) ] );
our $INOTIFY;

our $DEBUG = $IO::Lambda::DEBUG{inotify} || 0;

sub inotify_one_server
{
	my ($inotify, $fh) = @_;

        unless ($fh) {
	        open $fh, "<&", $inotify-> fileno or die "can't dup inotify handle:$!";
        }

	$inotify-> blocking(0);

	lambda {
		context $fh;
		readable {
			$inotify-> poll;
			if ($inotify-> {io_lambda_condvar}) {
				$inotify-> {io_lambda_condvar}-> terminate;
				delete $inotify-> {io_lambda_condvar};
			}
			again;
		}
	}
}

sub inotify_server 
{
	my @k = @_;
	lambda {
		context map { inotify_one_server $_ } @k;
		&tails();
	};
}

sub inotify
{
	return inotify_auto(@_) unless $_[0] and ref($_[0]) and $_[0]->isa('Linux::Inotify2');
	return inotify_timeout(@_) if 4 == @_ and defined $_[3];
	return inotify_plain(@_);
}

sub inotify_plain
{
	my ( $inotify, $path, $flags ) = @_;

	my @queue;
	my $watch = $inotify-> watch( $path, $flags, sub { 
		my $event = shift;
		push @queue, $event || $!;
		if ( $DEBUG ) {
			if ( $event ) {
				warn "event $inotify.". $event-> w . " $event\n" if $DEBUG;
			} else {
				warn "event on $inotify failed :$!\n" if $DEBUG;
			}
		}
	} );

	unless ( $watch ) {
		my $error = $!;
		warn "$inotify.watch($path,$flags) = $error\n" if $DEBUG;
		return lambda { (undef, $error) };
	}

	warn "new $watch\n" if $DEBUG;

	unless ( $inotify-> {io_lambda_server} ) {
	        my $fh;
		warn "auto-start $inotify\n" if $DEBUG;
                unless ( open $fh, , "<&", $inotify-> fileno) {
                        my $error = $!;
                        $watch-> cancel;
                        return lambda{ (undef, "can't dup inotify handle:$error") };
                }
		$inotify-> {io_lambda_server} = inotify_one_server($inotify);
		$inotify-> {io_lambda_server}-> start;
	}
	$inotify-> {io_lambda_refcnt}++;
	
	my $scope_exit = bless sub {
		warn "auto-cancel $watch\n" if $DEBUG;

		unless (--$inotify-> {io_lambda_refcnt}) {
			warn "auto-stop $inotify\n" if $DEBUG;
			$inotify-> {io_lambda_server}-> terminate;
			undef $inotify-> {io_lambda_server};
		}
		$watch-> cancel;
	}, __PACKAGE__;
	

	# this lambda will be called on again and again
	return lambda {
		unless ( $watch-> {inotify} ) {
			warn "$watch was cancelled\n" if $DEBUG;
			return undef, 'watcher is expired';
		}

		my $scope_keeper = $scope_exit;

		my $listener = $inotify-> {io_lambda_condvar} //= lambda {};
		$listener-> bind;
		context $listener;
		tail {
			unless (@queue) {
				this-> start;
				return; # not our watcher 
			}

			my $event = shift @queue;
			warn "[$event]\n" if $DEBUG;
			return ref($event) ? ($event) : (undef, $event);
		}
	}
}

sub inotify_auto
{
	my @stuff = @_;

	$INOTIFY ||= Linux::Inotify2-> new;
	unless ( $INOTIFY ) {
		my $error = $!;
		warn "Linux::Inotify2-> new(): $error\n" if $DEBUG;
		return lambda { (undef, $error) };
	}

	return inotify( $INOTIFY, @stuff );
}

sub inotify_timeout
{
	my ( $inotify, $path, $flags, $timeout ) = @_;

	my $watch = inotify_plain($inotify, $path, $flags);

	return lambda {
		context $watch;
		tail    { this-> terminate; return @_ };

		context $timeout;
		timeout { this-> terminate; return undef, 'timeout' };
	}
}

sub DESTROY { shift-> () }

1;

__DATA__

=pod

=head1 NAME

IO::Lambda::Inotify - bridge between IO::Lambda and Linux::Inotify2

=head1 SYNOPSIS
   
Easy

   use strict ;
   use IO::Lambda qw(:all);
   use IO::Lambda::Inotify qw(inotify);

   lambda {
      context inotify( "/tmp/xxx", IN_ACCESS, 3600);
      tail {
         my ( $e, $error ) = @_;

	 if ($error) {
            print "timed out\n" if $error eq 'timeout';
            print "error:$error\n";
            return;
	 }

         my $name = $e->fullname;
         print "$name was accessed\n" if $e->IN_ACCESS;
         print "$name is no longer mounted\n" if $e->IN_UNMOUNT;
         print "$name is gone\n" if $e->IN_IGNORED;
         print "events for $name have been lost\n" if $e->IN_Q_OVERFLOW;
      }
   }-> wait;

Explicit inotify object, share with other users

   use strict;
   use IO::Lambda qw(:all);
   use Linux::Inotify2;
   use IO::Lambda::Inotify qw(inotify);

   my $inotify = new Linux::Inotify2 or die "unable to create new inotify object: $!";

   lambda {
      context inotify($inotify, "/tmp/xxx", IN_ACCESS, 3600);
      tail {
         my ( $e, $error ) = @_;
	 if ($error) {
            print "timed out\n" if $error eq 'timeout';
            print "error:$error\n";
            return;
	 }

         my $name = $e->fullname;
         print "$name was accessed\n" if $e->IN_ACCESS;
         print "$name is no longer mounted\n" if $e->IN_UNMOUNT;
         print "$name is gone\n" if $e->IN_IGNORED;
         print "events for $name have been lost\n" if $e->IN_Q_OVERFLOW;
      }
   }-> wait;

inotify native watcher style - needs extra step with C<inotify_server>.

   use strict ;
   use IO::Lambda qw(:all);
   use Linux::Inotify2;
   use IO::Lambda::Inotify qw(:all);
   
   sub timer {
       my $timeout = shift ;
       lambda {
           context $timeout ;
           timeout {
               print "RECEIVED A TIMEOUT\n" ;
           }
       }
   }
   
   # create a new object
   my $inotify = new Linux::Inotify2
      or die "unable to create new inotify object: $!";
   
   # add watchers
   $inotify->watch ("/tmp/xxx", IN_ACCESS, sub {
       my $e = shift;
       my $name = $e->fullname;
       print "$name was accessed\n" if $e->IN_ACCESS;
       print "$name is no longer mounted\n" if $e->IN_UNMOUNT;
       print "$name is gone\n" if $e->IN_IGNORED;
       print "events for $name have been lost\n" if $e->IN_Q_OVERFLOW;
       
       # cancel this watcher: remove no further events
       $e->w->cancel;
   });
   
   my $server = inotify_server($inotify);
   $server->start;
   timer(10)->wait ;

=head1 DESCRIPTION

The module is a bridge between Linux::Inotify2 and IO::Lambda. It uses
lambda-style wrappers for subscribe and listen to inotify events, in the more
or less the same interface as Linux::Inotify2 does, but with extra timeout
capability for free.

The module can also be absolutely non-invasive, and one can just use the
non-blocking programming style advertized by Linux::Inotify2 . The only
requirements for the programmer is to register $inotify objects with
C<inotify_server> and let the resulting lambda running forever, or stop it when
the $inotify object is not needed anymore.

=head2 inotify ([ $inotify ], $path, $flags [, $timeout ]) :: () -> ( $event, $error )

C<inotify> creates and returns a lambda, that registers a watcher on $path using
$flags ( see Linux manpage for inotify ). On success, the lambda returns $event objects
of type Linux::Inotify2::Event (exactly as Linux::Inotify2 does), on failure, $event is undefined,
and $error is set.

If $timeout is specified, and expired, $error is set to C<'timeout'>

If no $inotify object is passed, then it is created automatically, and stays alive until
the end of the program. It is also reused for other such calls.

=head2 inotify_server( $inotify, ... ) :: () -> ()

Accepts one or more $inotify objects, creates a lambda that serves as a proxy for Linux::Inotify2
event loop. Use only when programming style compatible with Linux::Inotify2 is needed.

=head1 SEE ALSO

L<IO::Lambda>, L<Linux::Inotify2>

=head1 AUTHORS

Idea: Peter Gordon

Implementation: Dmitry Karasik, E<lt>dmitry@karasik.eu.orgE<gt>.

=cut
