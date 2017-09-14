package Log::WarnDie;

use warnings;
use strict;

# Make sure we have the modules that we need

use IO::Handle ();
use Scalar::Util qw(blessed);

# The logging dispatcher that should be used
# The (original) error output handle
# Reference to the previous parameters sent

our $DISPATCHER;
our $FILTER;
our $STDERR;
our $LAST;

# Old settings of standard Perl logging mechanisms

our $WARN;
our $DIE;

=head1 NAME

Log::WarnDie - Log standard Perl warnings and errors on a log handler

=head1 VERSION

Version 0.09

=head1 SYNOPSIS

    use Log::WarnDie; # install to be used later
    use Log::Dispatch;

    my $dispatcher = Log::Dispatch->new();       # can be any dispatcher!
    $dispatcher->add( Log::Dispatch::Foo->new( # whatever output you like
     name      => 'foo',
     min_level => 'info',
    ) );

    use Log::WarnDie $dispatcher; # activate later

    Log::WarnDie->dispatcher( $dispatcher ); # same

    warn "This is a warning";       # now also dispatched
    die "Sorry it didn't work out"; # now also dispatched

    no Log::WarnDie; # deactivate later

    Log::WarnDie->dispatcher( undef ); # same

    Log::WarnDie->filter(\&filter);
    warn "This is a warning"; # no longer dispatched
    die "Sorry it didn't work out"; # no longer dispatched

    # Filter out File::stat noise
    sub filter {
	    return ($_[0] !~ /^S_IFFIFO is not a valid Fcntl macro/);
    }

=head1 DESCRIPTION

The "Log::WarnDie" module offers a logging alternative for standard
Perl core functions.  This allows you to use the features of e.g.
L<Log::Dispatch>, L<Log::Any> or L<Log::Log4perl> B<without> having to make extensive
changes to your source code.

When loaded, it installs a __WARN__ and __DIE__ handler and intercepts any
output to STDERR.  It also takes over the messaging functions of L<Carp>.
Without being further activated, the standard Perl logging functions continue
to be executed: e.g. if you expect warnings to appear on STDERR, they will.

Then, when necessary, you can activate actual logging through e.g.
Log::Dispatch by installing a log dispatcher.  From then on, any warn, die,
carp, croak, cluck, confess or print to the STDERR handle,  will be logged
using the Log::Dispatch logging dispatcher.  Logging can be disabled and
enabled at any time for critical sections of code.

=cut

our $VERSION = '0.09';

=head1 SUBROUTINES/METHODS

=cut

#---------------------------------------------------------------------------

# Tie subroutines need to be known at compile time, hence there here, near
# the start of code rather than near the end where these would normally live.

#---------------------------------------------------------------------------
# TIEHANDLE
#
# Called whenever a dispatcher is activated
#
#  IN: 1 class with which to bless
# OUT: 1 blessed object 

sub TIEHANDLE { bless \"$_[0]",$_[0] } #TIEHANDLE

#---------------------------------------------------------------------------
# PRINT
#
# Called whenever something is printed on STDERR
#
#  IN: 1 blessed object returned by TIEHANDLE
#      2..N whatever was needed to be printed

sub PRINT {

# Lose the object
# If there is a dispatcher
#  Put it in the log handler if not the same as last time
#  Reset the flag
# Make sure it appears on the original STDERR as well

    shift;
    if($FILTER) {
    	return unless($FILTER->(@_));
    }
    if ($DISPATCHER) {
        $DISPATCHER->error( @_ )
         unless $LAST and @$LAST == @_ and join( '',@$LAST ) eq join( '',@_ );
        undef $LAST;
    }
    if($STDERR) {
	print $STDERR @_;
    }
} #PRINT

#---------------------------------------------------------------------------
# PRINTF
#
# Called whenever something is printed on STDERR using printf
#
#  IN: 1 blessed object returned by TIEHANDLE
#      2..N whatever was needed to be printed

sub PRINTF {

# Lose the object
# If there is a dispatcher
#  Put it in the log handler if not the same as last time
#  Reset the flag
# Make sure it appears on the original STDERR as well

    shift;
    if($FILTER) {
    	return unless($FILTER->(@_));
    }
    if ($DISPATCHER) {
        $DISPATCHER->error( @_ )
         unless $LAST and @$LAST == @_ and join( '',@$LAST ) eq join( '',@_ );
        undef $LAST;
    }
    if($STDERR) {
	printf $STDERR @_;
    }
} #PRINTF

#---------------------------------------------------------------------------
# CLOSE
#
# Called whenever something tries to close STDERR
#
#  IN: 1 blessed object returned by TIEHANDLE
#      2..N whatever was needed to be printed

sub CLOSE {

# Lose the object
# If there is a dispatcher
#  Put it in the log handler if not the same as last time
#  Reset the flag
# Make sure it appears on the original STDERR as well

    my $keep = $STDERR;
    $STDERR = undef;
    close $keep;	# So that the return status can be checked
} #CLOSE

#---------------------------------------------------------------------------
# OPEN
#
# Called whenever something tries to (re)open STDERR
#
#  IN: 1 blessed object returned by TIEHANDLE
#      2..N whatever was needed to be printed

sub OPEN {

# Lose the object
# If there is a dispatcher
#  Put it in the log handler if not the same as last time
#  Reset the flag
# Make sure it appears on the original STDERR as well

	shift;
	my $arg1 = shift;
	my $arg2 = shift;

	open($STDERR, $arg1, $arg2);
} #OPEN
#---------------------------------------------------------------------------
# At compile time
#  Create new handle
#  Make sure it's the same as the current STDERR
#  Make sure the original STDERR is now handled by our sub

BEGIN {
    $STDERR = new IO::Handle;
    $STDERR->fdopen( fileno( STDERR ),"w" )
     or die "Could not open STDERR 2nd time: $!\n";
    tie *STDERR,__PACKAGE__;

#  Save current __WARN__ setting
#  Replace it with a sub that
#   If there is a dispatcher
#    Remembers the last parameters
#    Dispatches a warning message
#   Executes the standard system warn() or whatever was there before

    $WARN = $SIG{__WARN__};
    $SIG{__WARN__} = sub {
	if($FILTER) {
		unless($FILTER->(@_)) {
			$WARN ? $WARN->( @_ ) : CORE::warn( @_ );
			return;
		}
	}
        if ($DISPATCHER) {
            $LAST = \@_;
	    if(ref($DISPATCHER) =~ /^Log::Log4perl/) {
		$DISPATCHER->warn( @_ );
	    } else {
		    $DISPATCHER->warning( @_ );
	   }
        }
        $WARN ? $WARN->( @_ ) : CORE::warn( @_ );
    };

#  Save current __DIE__ setting
#  Replace it with a sub that
#   If there is a dispatcher
#    Remembers the last parameters
#    Dispatches a critical message
#   Executes the standard system die() or whatever was there before

    $DIE = $SIG{__DIE__};
    $SIG{__DIE__} = sub {
	# File::stat goes to long efforts to not display the Fcntl message - then we go and display it,
	#	so let's not do that
	# TODO: would be better to set a list of messages to be filtered out
	if ($DISPATCHER && ($_[0] !~ /^S_IFFIFO is not a valid Fcntl macro/)) {
		if($FILTER) {
			unless($FILTER->(@_)) {
				if($DIE) {
					$DIE->(@_);
				} else {
					return unless((defined $^S) && ($^S == 0));	# Ignore errors in eval
					CORE::die(@_);
				}
			}
		}
            $LAST = \@_;
	    if(ref($DISPATCHER) =~ /^Log::Log4perl/) {
		$DISPATCHER->fatal( @_ );
	    } else {
		    $DISPATCHER->critical( @_ );
	   }
        }
	# Handle http://stackoverflow.com/questions/8078220/custom-error-handling-is-catching-errors-that-normally-are-not-displayed
	# $DIE ? $DIE->( @_ ) : CORE::die( @_ );
	if($DIE) {
		$DIE->(@_);
	} else {
		return unless((defined $^S) && ($^S == 0));	# Ignore errors in eval
		CORE::die(@_);
	}
    };

#  Make sure we won't be listed ourselves by Carp::

    $Carp::Internal{__PACKAGE__} = 1;
} #BEGIN

# Satisfy require

1;

#---------------------------------------------------------------------------

# Class methods

#---------------------------------------------------------------------------

=head2 dispatcher

Class method to set and/or return the current dispatcher

# IN: 1 class (ignored)
#     2 new dispatcher (optional)
# OUT: 1 current dispatcher

=cut

sub dispatcher {

# Return the current dispatcher if no changes needed
# Set the new dispatcher

    return $DISPATCHER unless @_ > 1;
    $DISPATCHER = $_[1];

# If there is a dispatcher now
#  If the dispatcher is a Log::Dispatch er
#   Make sure all of standard Log::Dispatch stuff becomes invisible for Carp::
#   If there are outputs already
#    Make sure all of the output objects become invisible for Carp::

    if ($DISPATCHER) {
        if ($DISPATCHER->isa( 'Log::Dispatch' )) {
            $Carp::Internal{$_} = 1
             foreach 'Log::Dispatch','Log::Dispatch::Output';
            if (my $outputs = $DISPATCHER->{'outputs'}) {
                $Carp::Internal{$_} = 1
                 foreach map {blessed $_} values %{$outputs};
            }
        }
    }

# Return the current dispatcher

    $DISPATCHER;
} #dispatcher

=head2 filter

Class method to set and/or get the current output filter

The given callback function should return 1 to output the given message, or 0
to drop it.
Useful for noisy messages such as File::stat giving S_IFFIFO is not a valid Fcntl macro.

=cut

sub filter {
	return $FILTER unless @_ > 1;
	$FILTER = $_[1];
}


#---------------------------------------------------------------------------

# Perl standard features

#---------------------------------------------------------------------------
# import
#
# Called whenever a -use- is done.
#
#  IN: 1 class (ignored)
#      2 new dispatcher (optional)

*import = \&dispatcher;

#---------------------------------------------------------------------------
# unimport
#
# Called whenever a -use- is done.
#
#  IN: 1 class (ignored)

sub unimport { import( undef ) } #unimport

#---------------------------------------------------------------------------

__END__

=head1 LOG LEVELS

The following log levels are used:

=head2 warning

Any C<warn>, C<Carp::carp> or C<Carp::cluck> will generate a "warning" level
message.

=head2 error

Any direct output to STDERR will generate an "error" level message.

=head2 critical

Any C<die>, C<Carp::croak> or C<Carp::confess> will generate a "critical"
level message.

=head1 REQUIRED MODULES

 Scalar::Util (1.08)

=head1 CAVEATS

The following caveats may apply to your situation.

=head2 Associated modules

Although a module such as L<Log::Dispatch> is B<not> listed as a prerequisite,
the real use of this module only comes into view when such a module B<is>
installed.  Please note that for testing this module, you will need the
L<Log::Dispatch::Buffer> module to also be available.

This module has been tested with
L<Log::Dispatch>, L<Log::Any> and L<Log::Log4perl>.
In principle any object which recognises C<warning>, C<error> and C<critical> should work.

=head2 eval

In the current implementation of Perl, a __DIE__ handler is B<also> called
inside an eval.  Whereas a normal C<die> would just exit the eval, the __DIE__
handler _will_ get called inside the eval.  Which may or may not be what you
want.  To prevent the __DIE__ handler to be called inside eval's, add the
following line to the eval block or string being evaluated:

    local $SIG{__DIE__} = undef;

This disables the __DIE__ handler within the evalled block or string, and
will automatically enable it again upon exit of the evalled block or string.
Unfortunately there is no automatic way to do that for you.

=head1 AUTHOR

Elizabeth Mattijsen, <liz@dijkmat.nl>

Maintained by Nigel Horne, C<< <njh at bandsman.co.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-log-warndie at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Log-WarnDie>.
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 COPYRIGHT

Copyright (c) 2004, 2007 Elizabeth Mattijsen <liz@dijkmat.nl>. All rights
reserved.  This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

Portions of versions 0.06 onwards, Copyright 2017 Nigel Horne

=cut
