package Log::Logger;

use vars qw($VERSION);

$Log::Logger::VERSION = "1.01";

use strict;

use IO::File;

=head1 NAME

Log::Logger - OO interface to user defined logfile

=head1 SYNOPSIS

    use Log::Logger;

    $lh = new Log::Logger;
    $lh->open("/tmp/mylog");
    $lh->log("Log this string");
    $lh->close();

    $lh = new Log::Logger "/tmp/mylog";
    $lh->log_print("Log and print this string");
    $lh->close();

    $lh = new Log::Logger;
    $lh->open_append("/tmp/mylog");
    $lh->log("Append this string");
    $lh->fail("Append this string and die");
    # Can't close $lh, because fail exits...

=head1 DESCRIPTION

Whenever writing scripts for system management, I always find myself
wishing to keep a log of what I have done.  But typing 

    print LOGHANDLE $progname . ": " . $stringToLog . "\n";

every time gets really old.  Similarly, C<die()> does not have the
facility to print to a logfile as it exits.  

A long time ago, I wrote two functions, C<log()> and C<fail()>, to
handle this problem.  I cut and pasted them everywhere.  But now that
Perl does modules for object reuse, I have ported them to a module
and added features.

C<Log::Logger> is esentially a wrapper around an C<IO::File> object.
The C<open> and C<open_append> functions just call 
C<IO::File-E<gt>open()>
with the appropriate arguments.  The useful functionality is in the 
C<log()>, C<log_print()>, and C<fail()> methods.  These methods make
logging what you are doing -- and printing to the user, if you like --
one line of code.  eg:

    # Old way
    print STDOUT "$progName: Running /var/clean script...\n";
    print LOGHANDLE "$progName: Running /var/clean script...\n";

    # Log::Logger way
    $lh->log_print("Running /var/clean script...");

And if you wish to log things, but also keep neat die() expressions,
you can.  eg:

    # Old way no logging
    system("foo") == 0 or die "Call to foo failed"

    # Old way, hackneyed logging
    system("foo") == 0 or do {
       print LOGHANDLE, "Call to foo failed";
       die "Call to foo failed";
    }

    # Log::Logger way
    system("foo") == 0 or $lh->fail("Call to foo failed");

Obviously, this is not a huge difference, but in a utility where
you keep track of a lot of operations, it just is easier, and saves
a little bit of typing.  Remember, one of the fundamental qualities
of a programmer is Laziness (see the Camel book).

=head1 CONSTRUCTOR

=over 4

=item new ([ FILENAME [, APPEND ] ])

Crates a new Log::Logger.  If it recieves an argument, that argument
is assumed to be a filename and the Log::Logger object attempts to
open the file for write.  If a second argument is passed and it 
evaluates to TRUE, the file is opened for append.

=back

=head1 METHODS

=over 4

=item open ( FILENAME )

Opens FILENAME for writing.  If this Log::Logger object already had
a logfile open, that file will be closed before the new file is opened.

Returns FALSE on failure.

=item open_append ( FILENAME )

Opens FILENAME for append.  If this Log::Logger object already had
a logfile open, that file will be closed before the new file is opened.

=item close ()

Closes the logfile.

=item log ( STRING )

Writes STRING to the logfile.  If there is no logfile open, does
nothing, and does it quietly.

=item log_print ( STRING )

Writes STRING to the logfile, printing it on STDOUT also.  If there is
no logfile open, it just prints to STDOUT.

=item fail ( STRING [, RETCODE ] )

Writes STRING to the logfile, printing it on STDOUT also.  It then 
calls exit() to exit the program.  If RETCODE is supplied, it exits 
with that return code.  Otherwise, it exits with a return code of 1.
If no logfile is open, it prints to STDOUT only, and exits.

=back

=head1 BUGS

None that I know of, except maybe this documentation.  Probably should
have an error checking return for <new()> with arguments like there
is on C<open()> and C<open_append()>.

=head1 AUTHOR

Joel Becker 	jlbec@ocala.cs.miami.edu

Copyright (c) 1998 Joel Becker.  All rights reserved.  This program
is free software; you can redistribute it and/or modify it under the
same terms as Perl itself.

=head1 VERSION

Version 1.01 (8 April 1998)

=head1 HISTORY

=over 4

=item Version 1.01

Documentation fixes.  Man, I thought it was clean.  Oops.

=item Version 1.00

Turned my C<log()> and C<fail()> subroutines into a proper Perl
module (this one).  Much better than cut-and-paste.

=back

=head1 SEE ALSO

L<IO::File(3)>

=cut

# Package variables
my ($fileName, $fileRef, $argv0);

# Setup package variables
BEGIN
{
   $fileName = 0;
   $fileRef = 1;
   $argv0 = $0;
   $argv0 =~ s%^.*/([^/]+)$%$1%;
}


#
# new()
#
# Builds the object, returns our blessed reference
#
sub new
{
   my ($proto, $fileToOpen, $append) = @_;
   my $class = ref($proto) || $proto;
   my $self = [];
   bless ($self, $class);
   $self->_initialize($fileToOpen, $append);
   return $self;
}


#
# initialize()
#
# Under the covers initializer.  Opens file, if one was 
# passed to new()
#
sub _initialize
{
   my ($self, $fileToOpen, $append) = @_;
   return unless defined($fileToOpen);

   ($append && $self->open_append($fileToOpen)) ||
      $self->open($fileToOpen);
}


#
# open()
# 
# Public method for opening a file for write
#
sub open
{
   my ($self, $fileToOpen) = @_;

   $self->[$fileName] = $fileToOpen;
   return $self->_open("> " . $fileToOpen);
}


# 
# open_append()
#
# Public method for opeing a file for append
#
sub open_append
{
   my ($self, $fileToOpen) = @_;

   $self->[$fileName] = $fileToOpen;
   return $self->_open(">> " . $fileToOpen);
}


#
# _open()
#
# Under the covers file open.  Opens file in the mode
# called.
#
sub _open
{
   my ($self, $fileString) = @_;

   # Close ourself if we have a logfile open already
   $self->close();

   $self->[$fileRef] = new IO::File($fileString);
   return defined($self->[$fileRef]);
}


#
# close()
#
# Closes the log, if open
#
sub close
{
   my $self = shift;

   # Automatically closes the file
   undef $self->[$fileRef] if defined $self->[$fileRef];
}


#
# log()
#
# Public method for logging a string
#
sub log
{
   my ($self, $logString) = @_;

   $self->_log($logString, 1);
}


# 
# log_print()
#
# Public method for logging a string, printing the string also
#
sub log_print
{
   my ($self, $logString) = @_;

   $self->_log($logString);
}
   

#
# fail()
#
# Logging equivalent of die().  Logs and prints the string,
# then exits with a non-zero return code;
#
sub fail
{
   my ($self, $logString, $retCode) = @_;

   $self->_log($logString);

   exit ($retCode || 1);
}


#
# _log()
#
# Under the covers method.  Actually does the logging.
#
sub _log
{
   my ($self, $logString, $logSilent) = @_;

   $logString = $argv0 . ": " . $logString . "\n";

   print STDOUT $logString unless $logSilent;
   $self->[$fileRef]->print($logString) if defined ($self->[$fileRef]);
   $self->[$fileRef]->flush();
}

1;
