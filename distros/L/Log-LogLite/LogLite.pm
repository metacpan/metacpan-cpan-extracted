package Log::LogLite;

use strict;
use vars qw($VERSION);

$VERSION = 0.82;

use Carp;
use IO::LockedFile 0.21;

my $TEMPLATE = '[<date>] <<level>> <called_by><default_message><message>
';
my $LOG_LINE_NUMBERS = 0; # by default we do not log the line numbers

##########################################
# new($filepath)
# new($filepath,$level)
# new($filepath,$level,$default_message)
##########################################
# the constructor
sub new {
    my $proto = shift; # get the class name
    my $class = ref($proto) || $proto;
    my $self  = {};
    # private data
    $self->{FILE_PATH} = shift; # get the file path of the config file
    $self->{LEVEL} = shift || 5; # the default level is 5
    # report when: 
    # 0  the application is unusable
    # 1  the application is going to be unusable
    # 2  critical conditions
    # 3  error conditions 
    # 4  warning conditions
    # 5  normal but significant condition
    # 6  informational
    # 7+ debug-level messages
    $self->{DEFAULT_MESSAGE} = shift || ""; # the default message
    $self->{TEMPLATE} = shift || $TEMPLATE; # the template
    $self->{LOG_LINE_NUMBERS} = $LOG_LINE_NUMBERS;
    # we create IO::LockedFile object that can be locked later
    $self->{FH} = new IO::LockedFile({ lock => 0 }, ">>".$self->{FILE_PATH});
    unless ($self->{FH}->opened) {
	croak("Log::LogLite: Cannot open the log file $self->{FILE_PATH}");
    }
    bless ($self, $class);
    return $self;
} # of new

##########################
# write($message, $level)
##########################
# will log the message in the log file only if $level>=LEVEL
sub write {
    my $self = shift;
    my $message = shift; # get the message are informational
    my $level = shift || "-";  
    if ($level ne "-" && $level > $self->{LEVEL}) { 
        # if the level of this message is higher
	# then the deafult level - do nothing
	return;
    }

    # lock the log file before we append 
    $self->{FH}->lock();

    # parse the template
    my $line = $self->{TEMPLATE};
    $line =~ s!<date>!date_string()!igoe;
    $line =~ s!<level>!$level!igo;
    $line =~ s!<called_by>!$self->called_by()!igoe;
    $line =~ s!<default_message>!$self->{DEFAULT_MESSAGE}!igo;
    $line =~ s!<message>!$message!igo;
    print {$self->{FH}} $line; 
    
    # unlock the file
    $self->{FH}->unlock();
} # of write   

##########################
# template()
# template($template)
##########################
sub template {
    my $self = shift;
    if (@_) { $self->{TEMPLATE} = shift }
    return $self->{TEMPLATE};
} # of template

##########################
# level()
# level($level)
##########################
# an interface to LEVEL
sub level {
    my $self = shift;
    if (@_) { $self->{LEVEL} = shift }
    return $self->{LEVEL};
} # of level

###########################
# default_message()
# default_message($message)
###########################
# an interface to DEFAULT_MESSAGE
sub default_message {
    my $self = shift;
    if (@_) { $self->{DEFAULT_MESSAGE} = shift }
    return $self->{DEFAULT_MESSAGE};
} # of default_message

##########################
# log_line_numbers()
# log_line_numbers($log_line_numbers)
##########################
# an interface to LOG_LINE_NUMBERS
sub log_line_numbers {
    my $self = shift;
    if (@_) { $self->{LOG_LINE_NUMBERS} = shift }
    return $self->{LOG_LINE_NUMBERS};
} # of log_line_numbers

#######################
# date_string()
#######################
sub date_string {
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
    # note that there is no Y2K bug here. see localtime in perlfunc.
    return sprintf("%02d/%02d/%04d %02d:%02d:%02d", 
		   $mday, $mon + 1, $year + 1900, $hour, $min, $sec);
} # of date_string

#######################
# called_by
#######################
sub called_by {
    my $self = shift;
    my $depth = 2;
    my $args; 
    my $pack; 
    my $file; 
    my $line; 
    my $subr; 
    my $has_args;
    my $wantarray;
    my $evaltext;
    my $is_require;
    my $hints;
    my $bitmask;
    my @subr;
    my $str = "";
    while (1) {
	($pack, $file, $line, $subr, $has_args, $wantarray, $evaltext, 
	 $is_require, $hints, $bitmask) = caller($depth);
	unless (defined($subr)) {
	    last;
	}
	$depth++;	
	$line = ($self->{LOG_LINE_NUMBERS}) ? "$file:".$line."-->" : "";
	push(@subr, $line.$subr);
    }
    @subr = reverse(@subr);
    foreach $subr (@subr) {
	$str .= $subr;
	$str .= " > ";
    }
    $str =~ s/ > $/: /;
    return $str;
} # of called_by

1;
__END__

############################################################################

=head1 NAME

Log::LogLite - The C<Log::LogLite> class helps us create simple logs for our application.   

=head1 SYNOPSIS

  use Log::LogLite;
  my $LOG_DIRECTORY = "/where/ever/our/log/file/should/be"; 
  my $ERROR_LOG_LEVEL = 6; 
               
  # create new Log::LogLite object
  my $log = new Log::LogLite($LOG_DIRECTORY."/error.log", $ERROR_LOG_LEVEL);

  ...

  # we had an error
  $log->write("Could not open the file ".$file_name.": $!", 4);

=head1 DESCRIPTION

In order to have a log we have first to create a C<Log::LogLite> object. 
The c<Log::LogLite> object is created with a logging level. The default 
logging level is 5. After the C<Log::LogLite> object is created, each call 
to the C<write> method may write a new line in the log file. If the level
of the message is lower or equal to the logging level, the message will 
be written to the log file. The format of the logging messages can be 
controled by changing the template, and by defining a default message.
The class uses the IO::LockedFile class.

=head1 CONSTRUCTOR

=over 4

=item new ( FILEPATH [,LEVEL [,DEFAULT_MESSAGE ]] )

The constructor. FILEPATH is the path of the log file. LEVEL is the defined
logging level - the LEVEL data member. DEFAULT_MESSAGE will define the 
DEFAULT_MESSAGE data member - a message that will be added to the message 
of each entry in the log (according to the TEMPLATE data member, see below).

The levels can be any levels that the user chooses to use. There are, 
though, recommended levels:
      0  the application is unusable
      1  the application is going to be unusable
      2  critical conditions
      3  error conditions 
      4  warning conditions
      5  normal but significant condition
      6  informational
      7+ debug-level messages

The default value of LEVEL is 5.
The default value of DEFAULT_MESSAGE is "".
Returns the new object. 

=back

=head1 METHODS

=over 4

=item write( MESSAGE [, LEVEL ] ) 

If LEVEL is less or equal to the LEVEL data member, or if LEVEL is undefined, 
the string in MESSAGE will be written to the log file.
Does not return anything. 

=item level( [ LEVEL ] ) 

Access method to the LEVEL data member. If LEVEL is defined, the LEVEL data 
member will get its value. 
Returns the value of the LEVEL data member. 

=item default_message( [ MESSAGE ] ) 

Access method to the DEFAULT_MESSAGE data member. If MESSAGE is defined, the
DEFAULT_MESSAGE data member will get its value. 
Returns the value of the DEFAULT_MESSAGE data member. 

=item log_line_numbers( [ BOOLEAN ] )

If this flag is set to true, the <called_by> string will hold the file 
that calls the subroutine and the line where the call is issued. The default
value is zero. 

=item template( [ TEMPLATE ] ) 

Access method to the TEMPLATE data member. The TEMPLATE data member is a string
that defines how the log entries will look like. The default TEMPLATE is:

'[<date>] <<level>> <called_by><default_message><message>'

Where:

      <date>           will be replaced by a string that represent 
                        the date. For example: 09/01/2000 17:00:13
      <level>          will be replaced by the level of the entry.
      <called_by>       will be replaced by a call trace string. For 
                        example:
                        CGIDaemon::listen > MyCGIDaemon::accepted 
      <default_message> will be replaced by the value of the 
                        DEFAULT_MESSAGE data member.
      <message>         will be replaced by the message string that 
                        is sent to the C<write> method.

Returns the value of the TEMPLATE data member. 

=head1 AUTHOR

Rani Pinchuk, rani@cpan.org

=head1 COPYRIGHT

Copyright (c) 2001-2002 Ockham Technology N.V. & Rani Pinchuk. 
All rights reserved.  
This package is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself.

=head1 SEE ALSO

L<IO::LockedFile(3)>

=cut
