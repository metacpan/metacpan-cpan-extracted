package Log::Dispatch::XML;
use base 'Log::Dispatch::Buffer';

# Make sure we have version info for this module
# Be strict from now on

$VERSION = '0.01';
use strict;

# Satisfy require

1;

#---------------------------------------------------------------------------
# xml
#
# Return the collected messages as XML.  Reset buffer unless inhibited.
#
#  IN: 1 instantiated object
#      2 name (+ optional attributes) of outer container (default: messages)
#      3 flag: inhibit flushing of messages
# OUT: 1 XML of all the collected messages

sub xml {

# Obtain the parameters
# Set the default container
# Set the close container
# Set the method to be used for fetching messages

    my ($self,$open,$method) = @_;
    $open ||= 'messages';
    my $close = $open =~ m#^([\w:\-]+)# ? $1 : '';
    $method = $method ? 'fetch' : 'flush';

# Obtain the messages
# Initialize the XML
# For all of the messages
#  Add the message to the XML
# Return final XML

    my $messages = $self->$method;
    my $xml = "<$open>";
    foreach (@{$messages}) {
        $xml .= "<$_->{'level'}><![CDATA[$_->{'message'}]]></$_->{'level'}>";
    }
    $xml."</$close>";
} #xml

#---------------------------------------------------------------------------

__END__

=head1 NAME

Log::Dispatch::XML - Collect one or more messages in XML format

=head1 SYNOPSIS

 use Log::Dispatch::XML ();

 my $dispatcher = Log::Dispatch->new;
 my $channel = Log::Dispatch::XML->new(
  name      => 'foo',
  min_level => 'info',
 ) );
 $dispatcher->add( $channel );

 $dispatcher->warning( "This is a warning" );

 my $xml = $channel->xml;
 # <messages><warning><![CDATA[This is a warning]]></warning></messages>

=head1 DESCRIPTION

The "Log::Dispatch::XML" module offers a buffering logging alternative for
XML users.  Messages are collected in the output channel until XML is created
from them.

=head1 ADDITIONAL METHODS

Apart from the methods provided by L<Log::Dispatch::Buffer> (and implicitely
from L<Log::Dispatch::Output>), the following method is available:

=head2 xml

 $xml = $channel->xml;

 $xml = $channel->xml( qq{log:messages xmlns:log="http://foo.com"} );

Return the XML of the messages collected on that channel.  Two optional input
parameters can be provided:

=over 2

=item 1 outer container

The name + attributes of the outer container that should be used to generate
the XML.  By default, "messages" will be assumed.

=item 2 inhibit flush

By default, once XML is generated from the messages, the messages are flushed
from the output channel.  Specifying a true value causes the messages B<not>
to be flushed.

=back

=head1 XML FORMAT

The XML format that is generated is very simple.  The name and the attributes
of the outer container is (implicitely) specified with the call to L</"xml">.
Inside this container, there is one container for each message: the name of
that container is the same as the level of the message.  The content of the
container, is the text of the message.  To ensure well-formedness of XML, the
message is put inside a CDATA section.

=head1 REQUIRED MODULES

 Log::Dispatch (1.16)
 Log::Dispatch::Buffer (any)

=head1 AUTHOR

Elizabeth Mattijsen, <liz@dijkmat.nl>.

Please report bugs to <perlbugs@dijkmat.nl>.

=head1 COPYRIGHT

Copyright (c) 2004 Elizabeth Mattijsen <liz@dijkmat.nl>. All rights
reserved.  This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
