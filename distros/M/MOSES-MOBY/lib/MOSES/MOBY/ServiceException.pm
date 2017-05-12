#-----------------------------------------------------------------
# MOSES::MOBY::ServiceException
# Author: Edward Kawas <edward.kawas@gmail.com>,
#         Martin Senger <martin.senger@gmail.com>
# For copyright and disclaimer see below.
#
# $Id: ServiceException.pm,v 1.4 2008/04/29 19:45:01 kawas Exp $
#-----------------------------------------------------------------

package MOSES::MOBY::ServiceException;
use base qw( MOSES::MOBY::Base Exporter );
use MOSES::MOBY::Tags;
use strict;
use vars qw( @EXPORT );

# add versioning to this module
use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.4 $ =~ /: (\d+)\.(\d+)/;

my %severityNames = ();
my %codeNames     = ();

use constant OK                         => 700;
use constant INFO                       => 3;
use constant ERROR                      => 1;
use constant WARNING                    => 2;
use constant UNKNOWN_NAME               => 200;
use constant INPUTS_INVALID             => 201;
use constant INPUT_NOT_ACCEPTED         => 202;
use constant INPUT_REQUIRED_PARAMETER   => 221;
use constant INPUT_INCORRECT_PARAMETER  => 222;
use constant INPUT_INCORRECT_SIMPLE     => 223;
use constant INPUT_INCORRECT_PARAMETERS => 224;
use constant INPUT_INCORRECT_COLLECTION => 225;
use constant INPUT_EMPTY_OBJECT         => 226;
use constant INPUT_INCORRECT_NAMESPACE  => 227;
use constant NOT_RUNNABLE               => 300;
use constant NOT_RUNNING                => 301;
use constant NOT_TERMINATED             => 302;
use constant NO_METADATA_AVAILABLE      => 400;
use constant PROTOCOLS_UNACCEPTED       => 500;
use constant INTERNAL_PROCESSING_ERROR  => 600;
use constant COMMUNICATION_FAILURE      => 601;
use constant UNKNOWN_STATE              => 602;
use constant NOT_IMPLEMENTED            => 603;

BEGIN {
    @EXPORT = qw(
		 ERROR
		 WARNING
		 INFO
		 OK
		 UNKNOWN_NAME
		 INPUTS_INVALID
		 INPUT_NOT_ACCEPTED
		 INPUT_REQUIRED_PARAMETER
		 INPUT_INCORRECT_PARAMETER
		 INPUT_INCORRECT_SIMPLE
		 INPUT_INCORRECT_PARAMETERS
		 INPUT_INCORRECT_COLLECTION
		 INPUT_EMPTY_OBJECT
		 INPUT_INCORRECT_NAMESPACE
		 NOT_RUNNABLE
		 NOT_TERMINATED
		 NO_METADATA_AVAILABLE
		 PROTOCOLS_UNACCEPTED
		 INTERNAL_PROCESSING_ERROR
		 COMMUNICATION_FAILURE
		 UNKNOWN_STATE
		 NOT_IMPLEMENTED
		 );

    # initialize severity names
    $severityNames{ ERROR() }   = 'error';
    $severityNames{ WARNING() } = 'warning';
    $severityNames{ INFO() }    = 'information';

    # initialize code names
    $codeNames{OK}                         = 'OK';
    $codeNames{UNKNOWN_NAME}               = 'UNKNOWN_NAME';
    $codeNames{INPUTS_INVALID}             = 'INPUTS_INVALID';
    $codeNames{INPUT_NOT_ACCEPTED}         = 'INPUT_NOT_ACCEPTED';
    $codeNames{INPUT_REQUIRED_PARAMETER}   = 'INPUT_REQUIRED_PARAMETER';
    $codeNames{INPUT_INCORRECT_PARAMETER}  = 'INPUT_INCORRECT_PARAMETER';
    $codeNames{INPUT_INCORRECT_SIMPLE}     = 'INPUT_INCORRECT_SIMPLE';
    $codeNames{INPUT_REQUIRED_PARAMETERS}  = 'INPUT_REQUIRED_PARAMETERS';
    $codeNames{INPUT_INCORRECT_COLLECTION} = 'INPUT_INCORRECT_COLLECTION';
    $codeNames{INPUT_EMPTY_OBJECT}         = 'INPUT_EMPTY_OBJECT';
    $codeNames{INPUT_INCORRECT_NAMESPACE}  = 'INPUT_INCORRECT_NAMESPACE';
    $codeNames{NOT_RUNNABLE}               = 'NOT_RUNNABLE';
    $codeNames{NOT_RUNNING}                = 'NOT_RUNNING';
    $codeNames{NOT_TERMINATED}             = 'NOT_TERMINATED';
    $codeNames{NO_METADATA_AVAILABLE}      = 'NO_METADATA_AVAILABLE';
    $codeNames{PROTOCOLS_UNACCEPTED}       = 'PROTOCOLS_UNACCEPTED';
    $codeNames{INTERNAL_PROCESSING_ERROR}  = 'INTERNAL_PROCESSING_ERROR';
    $codeNames{COMMUNICATION_FAILURE}      = 'COMMUNICATION_FAILURE';
    $codeNames{UNKNOWN_STATE}              = 'UNKNOWN_STATE';
    $codeNames{NOT_IMPLEMENTED}            = 'NOT_IMPLEMENTED';
}

#-----------------------------------------------------------------
# A list of allowed attribute names. See MOSES::MOBY::Base for details.
#-----------------------------------------------------------------
{
    my %_allowed = (
		    severity => { type => MOSES::MOBY::Base->INTEGER },
		    code     => { type => MOSES::MOBY::Base->INTEGER },
		    message  => undef,
		    jobId    => undef,
		    dataName => undef,
		    );

    sub _accessible {
	my ( $self, $attr ) = @_;
	exists $_allowed{$attr} or $self->SUPER::_accessible($attr);
    }

    sub _attr_prop {
	my ( $self, $attr_name, $prop_name ) = @_;
	my $attr = $_allowed{$attr_name};
	return ref($attr) ? $attr->{$prop_name} : $attr if $attr;
	return $self->SUPER::_attr_prop( $attr_name, $prop_name );
    }
}

#-----------------------------------------------------------------
# init
#-----------------------------------------------------------------
sub init {
    my ($self) = shift;
    $self->SUPER::init();
    $self->severity (INFO);
    $self->code (OK);
}

#-----------------------------------------------------------------
# getErrorCodeAsString
#-----------------------------------------------------------------
sub getErrorCodeAsString {
    my $self = shift;
    return $codeNames{ $self->code } || '';
}

#-----------------------------------------------------------------
# getSeverityAsString
#-----------------------------------------------------------------
sub getSeverityAsString {
    my $self = shift;
    return $severityNames{ $self->severity } || '';
}

#-----------------------------------------------------------------
# toXML
#-----------------------------------------------------------------
sub toXML {
    my $self = shift;
    $self->increaseXMLCounter;

    my $root = $self->createXMLElement(MOBYEXCEPTION);
    $self->setXMLAttribute( $root, REFQUERYID, $self->jobId );
    $self->setXMLAttribute( $root, REFELEMENT, $self->dataName );

    # error code element
    if ( $self->code ) {
	my $elemCode = $self->createXMLElement(EXCEPTIONCODE);
	$elemCode->appendText( $self->code );
	$root->appendChild($elemCode);
    }

    # message element
    if ( $self->message ) {
	my $elemMessage = $self->createXMLElement(EXCEPTIONMESSAGE);
	$elemMessage->appendText( $self->message );
	$root->appendChild($elemMessage);
    }

    return $self->closeXML($root);
}

#-----------------------------------------------------------------
# extractExceptions
#
# Extract and return all exceptions from the given serviceNotes XML
# element.
#-----------------------------------------------------------------
sub extractExceptions {
    my ( $self, $element ) = @_;
    return [] unless $element;
    my @result = ();

    foreach my $exElem ( $element->getChildrenByTagName(MOBYEXCEPTION) ) {
	my $ex = $self->_extractException($exElem);
	push( @result, $ex ) if $ex;
    }
    foreach my $exElem
	( $element->getChildrenByTagNameNS( MOBY_XML_NS, MOBYEXCEPTION ) ) {
	    my $ex = $self->_extractException($exElem);
	    push( @result, $ex ) if $ex;
	}

    return \@result;
}

#-----------------------------------------------------------------
# _extractException
#   Create and return a MOSES::MOBY::ServiceException from the given
#   XML $element (must be a 'mobyException' element)
#-----------------------------------------------------------------
sub _extractException {
    my ( $self, $element ) = @_;
    my $result = new MOSES::MOBY::ServiceException;
    $result->severity( getXMLAttribute( $element, SEVERITY ) );

    # note: should only be one child in a properly formatted exception
    foreach my $code ( $element->getChildrenByTagName(EXCEPTIONCODE) ) {
	$result->code( $code->textContent );
    }

    my $message;

    # note: should only be one child in a properly formatted exception
    foreach my $msg ( $element->getChildrenByTagName(EXCEPTIONMESSAGE) ) {
	$result->message( $msg->textContent );
    }

    return $result;
}

#-----------------------------------------------------------------
# error
#
# Create an instance of ServiceException that represents an error.  It
# has either a single argument representing an error message, or a
# hash ref with recognized keys 'code' and 'msg'.
#
#-----------------------------------------------------------------
sub error {
    my $self = shift;

    # make an instance, if called as a class method
    unless (ref $self) {
	no strict 'refs'; 
	$self = $self->new;
    }

    my ($msg, $code);
    if ( @_ > 0 ) {
	if ( ref( $_[0] ) eq 'HASH' ) {
	    $msg  = $_[0]->{msg};
	    $code = $_[0]->{code};
	} else {
	    $msg = $_[0];
	}
    } else {
	$code = INTERNAL_PROCESSING_ERROR;
    }
    $self->severity (ERROR);
    $self->message ($msg || '');
    $self->code ($code || INTERNAL_PROCESSING_ERROR);
    return $self;
}

#-----------------------------------------------------------------
# warning
#-----------------------------------------------------------------
sub warning {
    my ($self, $msg) = @_;

   # make an instance, if called as a class method
   unless (ref $self) {
       no strict 'refs'; 
       $self = $self->new;
   }

    $self->severity (WARNING);
    $self->message ($msg || '');
    return $self;
}

#-----------------------------------------------------------------
# info
#-----------------------------------------------------------------
sub info {
    my ($self, $msg) = @_;

   # make an instance, if called as a class method
   unless (ref $self) {
       no strict 'refs'; 
       $self = $self->new;
   }

    $self->severity (INFO);
    $self->message ($msg || '');
    return $self;
}

1;
__END__

=head1 NAME

MOSES::MOBY::ServiceException - 

=head1 SYNOPSIS

 use MOSES::MOBY::ServiceException;
 
 # initialize %params as you see fit, for example:
 my %params = (
				   code     => INPUTS_INVALID(),
				   severity => ERROR(),
				   jobId    => 'a1',
				   dataName => 'myBasicGFFSequenceFeature',
				   message  => 'there was something wrong with GFF'
	);
 
 my $serviceException = MOSES::MOBY::ServiceException->new(%params);
 
 my $articleName = $serviceException->dataName();
 $serviceException->dataName($articleName);
 
 my $code = $serviceException->code();
 $serviceException->code($code);
 
 my $formattedText = $serviceException->formatString(2);
 
 my $errorString = $serviceException->getErrorCodeAsString();
 
 my $severityString = $serviceException->getSeverityAsString();
 
 my $jobId = $serviceException->jobId();
 $serviceException->jobId(id => $jobId);
 
 my $message = $serviceException->message();
 $serviceException->message($message);
 
 my $severityCode = $serviceException->severity();
 $serviceException->severity($severityCode);
 
 my $string = $serviceException->toString();

 my $domElement = $serviceException->toXML();
 
 #instantiate ServiceException objects flexibly:
 
 # for an error (set up params as appropriate)
 %params = (code => OK(), msg => "ERROR ERROR ERROR");
 $serviceException = MOSES::MOBY::ServiceException::error(%params);
 
 # for info (set up params as appropriate)
 %params = (msg => "INFO INFO INFO");
 $serviceException = MOSES::MOBY::ServiceException::info(%params);
 
 # for a warning (set up params as appropriate)
 %params = (msg => "WARN WARN WARN");
 $serviceException = MOSES::MOBY::ServiceException::warning(%params);

 
=cut

=head1 DESCRIPTION
	
	This module encapsulates a Moby service exception raised by 
	service providers when something wrong has to be reported 
	to a client. These exceptions are carried in the service 
	notes part of a MobyPackage.
	
	Also included in this module are constances for known error
	codes and for exception severity levels.

=head1 ACCESSIBLE ATTRIBUTES

Details are in L<MOSES::MOBY::Base>. Here just a list of them:

=over

=item B<severity>

An integer representing a severity code.

=item B<code>

An integer representing an error code.

=item B<message>

A texual message explaining this exception.

=item B<jobId>

An identifier of a job that caused this exception.

=item B<dataName>

An article name containing the offending data input.

=back

=head1 SUBROUTINES

=head2 info

Create an instance of ServiceException that represents an C<info
exception>. An argument is a message text.

=head2 warning

Create an instance of ServiceException that represents an C<warning
exception>. An argument is a message text.

=head2 error

Create an instance of ServiceException that represents an error.  It
has either a single argument representing an error message, or a hash
with recognized keys C<code> and C<msg>.

exception>. An argument is a message text.
 Function     : Create an instance of ServiceException that represents an error.
 Returns      : An instance of ServiceException
 Args         : An optional Hash argument with any or all of the following:
 					code: an error code


=head2 extractExceptions

Extract and return all exceptions from the given serviceNotes XML
element.

This is a convenient method that can be used when dealing with an XML
response from a service without parsing the whole response to a
Moby::Package.

An argument is an C<XML::LibXML::Element> containing the serviceNotes
(a place where are stored exceptions).

Returned value is a reference to an array of
C<MOSES::MOBY::ServiceException>s. Return a reference to an empty array if
there are no exceptions.

=head2 getSeverityAsString

Return the current severity level as text. Or an empty string if the
severity code is unknown.


=head2 getErrorCodeAsString

Return a stringified form of the error code associated with this
exception. Or an empty string if the error code is unknown.


=head1 CONSTANT SUBROUTINES

The following subroutines represents all error codes and similar
constants, as defined by BioMoby API.

=head2 ERROR

Returns A severity code that corresponds to a fatal error

No arguments

=cut

=head2 WARNING

Returns a severity code that corresponds to an informative diagnostic message

No arguments

=cut	

=head2 INFO

Returns a severity code that corresponds to a message not related to any error

No arguments

=cut

=head2 OK

Returns an error code: No error. Used together with severity code 
INFO indicating that actually no error occured and the service was 
executed normally.

No arguments

=cut

=head2 UNKNOWN_NAME

Returns an error code: Setting input data under a non-existing name,
or asking for a result using an unknown name

No arguments

=cut

=head2 INPUTS_INVALID

Returns an error code: Input data are invalid; they do not match 
with their definitions, or with their dependency conditions

No arguments

=cut

=head2 INPUT_NOT_ACCEPTED

Returns an error code: Used when a client tries to send input data
to a job created in a previous call but the server does
not any more accept input data.

No arguments

=cut

=head2 INPUT_REQUIRED_PARAMETER

Returns an error code: Service requires a parameter but none was given

No arguments

=cut

=head2 INPUT_INCORRECT_PARAMETER

Returns an error code: Given parameter is incorrect

No arguments

=cut

=head2 INPUT_INCORRECT_SIMPLE

Returns an error code: Given input of type Simple is incorrect

No arguments

=cut

=head2 INPUT_INCORRECT_PARAMETERS

Returns an error code: Service requires two or more data inputs.

No arguments

=cut

=head2 INPUT_INCORRECT_COLLECTION

Returns an error code: Given input of type Collection is incorrect.

No arguments

=cut

=head2 INPUT_EMPTY_OBJECT

Returns an error code: Given an empty input data.

No arguments

=cut

=head2 INPUT_INCORRECT_NAMESPACE

Returns an error code: Incorrect Namespace in the input object.

No arguments

=cut

=head2 NOT_RUNNABLE


Returns an error code: The same job (analysis) has already 
been executed, or the data that had been set 
previously do not exist or are not accessible 
anymore.

No arguments

=cut

=head2 NOT_RUNNING

Returns an error code: A job (analysis) has not yet been 
started. Note that this exception is not 
raised when the job has been already finished.

No arguments

=cut

=head2 NOT_TERMINATED

Returns an error code: For some reasons, a job (analysis)
is not interruptible, but an attempt to do so 
was done.

No arguments

=cut

=head2 NO_METADATA_AVAILABLE

Returns an error code: There are no metadata available for 
the executed service/analysis.

No arguments

=cut

=head2 PROTOCOLS_UNACCEPTED

Returns an error code: Used when a service does not agree 
on using any of the proposed notification protocols

No arguments

=cut

=head2 INTERNAL_PROCESSING_ERROR

Returns an error code: A placeholder for all other errors 
not defined explicitly in the Biomoby API.

No arguments

=cut

=head2 COMMUNICATION_FAILURE

Returns an error code: A generic network failure.

No arguments

=cut

=head2 UNKNOWN_STATE

Returns an error code: Used when a service call expects 
to find an existing state but failed.

No arguments

=cut

=head2 NOT_IMPLEMENTED

Returns an error code: A requested method is not implemented.

No arguments


=head1 AUTHORS

 Edward Kawas (edward.kawas [at] gmail [dot] com)
 Martin Senger (martin.senger [at] gmail [dot] com)

=cut

