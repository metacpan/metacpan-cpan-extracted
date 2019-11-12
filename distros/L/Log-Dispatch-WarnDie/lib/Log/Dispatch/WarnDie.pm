package Log::Dispatch::WarnDie;

# Make sure we have version info for this module
# Be strict from now on

$VERSION = '0.04';
use strict;

# The logging dispatcher that should be used

my $DISPATCHER;

# Old settings of standard Perl logging mechanisms

my $WARN;
my $DIE;

# At compile time
#  Save current __WARN__ setting
#  Replace it with a sub that
#   Dispatches a warning message if there is a dispatcher
#   Executes the standard system warn() or whatever was there before

BEGIN {
    $WARN = $SIG{__WARN__};
    $SIG{__WARN__} = sub {
        $DISPATCHER->warning( $_[0] ) if $DISPATCHER;
        $WARN ? $WARN->( $_[0] ) : CORE::warn( $_[0] );
    };

#  Save current __DIE__ setting
#  Replace it with a sub that
#   Dispatches an error message if there is a dispatcher
#   Executes the standard system die() or whatever was there before

    $DIE = $SIG{__DIE__};
    $SIG{__DIE__} = sub {
        $DISPATCHER->error( $_[0] ) if $DISPATCHER;
        $DIE ? $DIE->( $_[0] ) : CORE::die( $_[0] );
    };

#  Make sure we won't be listed ourselves by Carp::

    $Carp::Internal{$_} = 1
     foreach 'Log::Dispatch','Log::Dispatch::Output',__PACKAGE__;
} #BEGIN

# Satisfy require

1;

#---------------------------------------------------------------------------

# Class methods

#---------------------------------------------------------------------------
# dispatcher
#
# Set and/or return the current dispatcher
#
#  IN: 1 class (ignored)
#      2 new dispatcher (optional)
# OUT: 1 current dispatcher

sub dispatcher {

# Set the new dispatcher if there is any
# Return the current dispatcher

    $DISPATCHER = $_[1] if @_ > 1;
    $DISPATCHER;
} #dispatcher

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

=head1 NAME

Log::Dispatch::WarnDie - Log standard Perl warnings and errors

=head1 SYNOPSIS

 use Log::Dispatch::WarnDie; # install to be used later

 my $dispatcher = Log::Dispatch->new;
 $dispatcher->add( Log::Dispatch::WarnDie->new(
  name      => 'foo',
  min_level => 'info',
 ) );

 use Log::Dispatch::WarnDie $dispatcher; # activate later

 Log::Dispatch::WarnDie->dispatcher( $dispatcher ); # same

 warn "This is a warning"; # now also dispatched
 die "Sorry it didn't work out"; # now also dispatched

 no Log::Dispatch::WarnDie; # deactivate later

 Log::Dispatch::WarnDie->dispatcher( undef ); # same

 warn "This is a warning"; # no longer dispatched
 die "Sorry it didn't work out"; # no longer dispatched

=head1 DESCRIPTION

The "Log::Dispatch::WarnDie" module offers a logging alternative for standard
Perl core functions.  This allows you to use the features of L<Log::Dispatch>
B<without> having to make extensive changes to your source code.

When loaded, it installs a __WARN__ and __DIE__ handler.  It also takes over
the messaging functions of L<Carp>.  Without being further activated, the
standard Perl logging functions continue to be done.

Then, when necessary, you can activate actual logging through Log::Dispatch
by installing a log dispatcher.  From then on, any warn, die, carp, croak,
cluck or confess will be logged using the Log::Dispatch logging dispatcher.
Logging can be disabled and enabled at any time for critical sections of code.

=head1 REQUIRED MODULES

 (none)

=head1 CAVEATS

The following caveats may apply to your situation.

=head2 Associated modules

Although L<Log::Dispatch> is B<not> listed as a prerequisite, the real use of
this module only comes into view when that module B<is> installed.  Please note
that for testing this module, you will need the L<Log::Dispatch::Buffer> module
to also be available.

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

Elizabeth Mattijsen, <liz@dijkmat.nl>.

maintained by LNATION, <thisusedtobeanemail@gmail.com>

Please report bugs to <perlbugs@dijkmat.nl>.

=head1 COPYRIGHT

Copyright (c) 2004 Elizabeth Mattijsen <liz@dijkmat.nl>. All rights
reserved.  This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
