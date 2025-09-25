# Taken from https://backpan.perl.org/modules/by-authors/id/E/EL/ELIZABETH/Log-Dispatch-Buffer-0.02.tar.gz
package Log::Dispatch::Buffer;
use base 'Log::Dispatch::Output';

# Make sure we have version info for this module
# Be strict from now on

$VERSION = '0.02';
use strict;

# Satisfy require

1;

#---------------------------------------------------------------------------
# new
#
# Required by Log::Dispatch::Output.  Creates a new Log::Dispatch::Buffer
# object
#
#  IN: 1 class
#      2..N parameters as a hash

sub new {   # too bad this can't be inherited from Log::Dispatch::Output

# Obtain the parameters
# Create an object
# Do the basic initializations
# Return the instantiated object

    my ($class,%p) = @_;
    my $self = bless {},ref $class || $class;
    $self->_basic_init( %p );
    $self;
} #new

#---------------------------------------------------------------------------
# log_message
#
# Required by Log::Dispatch.  Log a single message.
#
#  IN: 1 instantiated object
#      2..N hash with parameters as required by Log::Dispatch

sub log_message {

# Obtain the parameters
# Save the parameters to the list

    my ($self,%p) = @_;
    push @{$self->{'messages'}},\%p;
} #log_message

#---------------------------------------------------------------------------
# flush
#
# Return the collected messages and remove them from the buffer.
#
#  IN: 1 instantiated object
# OUT: 1 reference to list with hashrefs of each message

sub flush { delete( $_[0]->{'messages'} ) || [] } #flush

#---------------------------------------------------------------------------
# fetch
#
# Return the collected messages and do _not_ remove them from the buffer.
#
#  IN: 1 instantiated object
# OUT: 1 reference to list with hashrefs of each message

sub fetch { $_[0]->{'messages'} || [] } #fetch

#---------------------------------------------------------------------------

__END__

=head1 NAME

Log::Dispatch::Buffer - Base class for collecting logged messages

=head1 SYNOPSIS

 use Log::Dispatch::Buffer ();

 my $channel = Log::Dispatch::Buffer->new(
  name      => 'foo',
  min_level => 'info',
 );
 my $dispatcher = Log::Dispatch->new
 $dispatcher->add( $channel );

 $dispatcher->warning( "This is a warning" );

 my $messages = $channel->fetch;

 my $messages = $channel->flush;

 $channel->flush;

=head1 VERSION

This documentation describes version 0.02.

=head1 DESCRIPTION

The "Log::Dispatch::Buffer" module is a base class that can als be used by
itself.  Its only function is to collect messages that are being logged to
it until they are obtained for further processing.  The reason for its
existence, was because the functionality was needed for L<Log::Dispatch::XML>.

=head1 ADDITIONAL METHODS

Apart from the methods required by L<Log::Dispatch::Output>, the following
additional methods are available for this class and any inherited class:

=head2 fetch

 $messages = $channel->fetch;

Obtain an array reference to the messages that have been collected since the
output channel was created, or since the last time the L</"flush"> method was
called.  Does B<not> remove messages from the object.

=head2 flush

 $messages = $channel->flush;

 $channel->flush;

Obtain an array reference to the messages that have been collected since the
output channel was created, or since the last time the "flush"> method was
called.  B<Removes> messages from the object.  Can also be called in void
context to simply remove all messages currently buffered in the output channel.

=head1 MESSAGE FORMAT

Each message is represented as a hash reference to the parameters originally
passed by L<Log::Dispatch::Output> to the "log_message" method (as described
in L<Log::Dispatch/"CONVENIENCE METHODS">)..

=head1 REQUIRED MODULES

 Log::Dispatch (1.16)

=head1 AUTHOR

Elizabeth Mattijsen, <liz@dijkmat.nl>.

Please report bugs to <perlbugs@dijkmat.nl>.

=head1 COPYRIGHT

Copyright (c) 2004, 2007 Elizabeth Mattijsen <liz@dijkmat.nl>. All rights
reserved.  This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
