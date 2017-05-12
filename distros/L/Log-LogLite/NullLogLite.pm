package Log::NullLogLite;

use strict;
use vars qw($VERSION @ISA);

$VERSION = 0.82;

# According to the Null pattern.
#
# Log::NullLogLite inherits from Log::LogLite and implement the Null 
# Object Pattern.
use Log::LogLite;
@ISA = ("Log::LogLite");
package Log::NullLogLite;
use strict;

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
    bless ($self, $class);
    return $self;
} # of new

########################
# write($message, $level)
########################
# will log the message in the log file only if $level>=LEVEL
sub write {
    my $self = shift;
} # of write   

##########################
# level()
# level($level)
##########################
# an interface to LEVEL
sub level {
    my $self = shift;
    return -1;
} # of level

###########################
# default_message()
# default_message($message)
###########################
# an interface to DEFAULT_MESSAGE
sub default_message {
    my $self = shift;
    return "";
} # of default_message

1;
__END__

############################################################################

=head1 NAME

Log::NullLogLite - The C<Log::NullLogLite> class implements the Null Object 
pattern for the C<Log::LogLite> class.

=head1 SYNOPSIS

  use Log::NullLogLite;
               
  # create new Log::NullLogLite object
  my $log = new Log::NullLogLite();

  ...

  # we had an error (this entry will not be written to the log 
  # file because we use Log::NullLogLite object).
  $log->write("Could not open the file ".$file_name.": $!", 4);

=head1 DESCRIPTION

The C<Log::NullLogLite> class is derived from the C<Log::LogLite> class 
and implement the Null Object Pattern to let us to use the C<Log::LogLite> 
class with B<null> C<Log::LogLite> objects.
We might want to do that if we use a C<Log::LogLite> object in our code, and
we do not want always to actually define a C<Log::LogLite> object (i.e. not 
always we want to write to a log file). In such a case we will create a 
C<Log::NullLogLite> object instead of the C<Log::LogLite> object, and will 
use that object instead.
The object has all the methods that the C<Log::LogLite> object has, but 
those methods do nothing. Thus our code will continue to run without any
change, yet we will not have to define a log file path for the 
C<Log::LogLite> object, and no log will be created.

=head1 CONSTRUCTOR

=over 4

=item new ( FILEPATH [,LEVEL [,DEFAULT_MESSAGE ]] )

The constructor. The parameters will not have any affect.
Returns the new Log::NullLogLite object. 


=back

=head1 METHODS

=over 4

=item write( MESSAGE [, LEVEL ] ) 

Does nothing. The parameters will not have any affect.
Returns nothing. 

=item level( [ LEVEL ] ) 

Does nothing. The parameters will not have any affect.
Returns -1. 

=item default_message( [ MESSAGE ] ) 

Does nothing. The parameters will not have any affect.
Returns empty string (""). 

=head1 AUTHOR

Rani Pinchuk, rani@cpan.org

=head1 COPYRIGHT

Copyright (c) 2001-2002 Ockham Technology N.V. & Rani Pinchuk. 
All rights reserved.  
This package is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Log::LogLite(3)>,
The Null Object Pattern - Bobby Woolf - PLoP96 - published in Pattern 
Languages of Program Design 3 (http://cseng.aw.com/book/0,,0201310112,00.html)

=cut
