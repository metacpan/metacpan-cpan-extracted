package  Hessian::Exception;

use strict;
use warnings;

use Exception::Class (
    'Hessian::Exception',
    'StandardHessian::X' => {
        isa         => 'Hessian::Exception',
        description => 'Set of exceptions defined by the official Hessian'
          . ' protocol.'
    },
    'Implementation::X' => {
        isa         => 'Hessian::Exception',
        description => 'Exceptions defined for internal use.'
    },
    'ProtocolException' => {
        isa         => 'StandardHessian::X',
        description => 'The Hessian request has some sort of syntactic error'
    },
    'InputOutput::X' => {
        isa         => 'Implementation::X',
        description => 'Unable to read/write to a file or string handle.'
    },
    'Parameter::X' => {
        isa         => 'Implementation::X',
        description => 'Incorrect or missing parameter to method'
    },
    'NoSuchObjectException' => {
        isa         => 'StandardHessian::X',
        description => 'The requested object does not exist.'
    },
    'NoSuchMethodException' => {
        isa         => 'StandardHessian::X',
        description => 'The requested method does not exists.'
    },
    'RequireHeaderException' => {
        isa         => 'StandardHessian::X',
        description => 'A required header was '
          . 'not understood by the server.'
    },
    'ServiceException' => {
        isa         => 'StandardHessian::X',
        description => 'The called method threw an exception.'
    },
    'EndOfInput::X' => {
        isa         => 'Implementation::X',
        description => 'Not an error. Should interrupt loop processing.'
    },
    'MessageIncomplete::X' => {
        isa         => 'Implementation::X',
        description => 'The serialized message string '
          . 'did not contain a complete message'
    }
);

"one, but we're not the same";

__END__


=head1 NAME

Hessian::Exception - Basic exceptions for the Hessian protocol.

=head1 VERSION

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 INTERFACE


