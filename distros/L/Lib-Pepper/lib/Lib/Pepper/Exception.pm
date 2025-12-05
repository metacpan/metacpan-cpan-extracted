package Lib::Pepper::Exception;
#---AUTOPRAGMASTART---
use v5.42;
use strict;
use diagnostics;
use mro 'c3';
use English;
use Carp qw[carp croak confess cluck longmess shortmess];
our $VERSION = 0.5;
use autodie qw( close );
use Array::Contains;
use utf8;
use Data::Dumper;
use Data::Printer;
#---AUTOPRAGMAEND---


use Lib::Pepper::Constants qw(:errors);

# Error code to message mapping
my %ERROR_MESSAGES = (
    # Success
    0 => 'Success',

    # Generic failures
    -1 => 'Generic failure',
    -2 => 'Invalid value provided',
    -3 => 'Invalid state',
    -4 => 'Functionality not licensed',
    -5 => 'Out of memory',

    # Library initialization errors
    -100 => 'Library initialization failed',
    -101 => 'Library already initialized',
    -102 => 'Library loading error',
    -103 => 'Library not initialized',
    -104 => 'Library version mismatch',
    -105 => 'Library dependency error',
    -106 => 'Library still in use',

    # Configuration errors
    -200 => 'Configuration error',
    -201 => 'Invalid configuration',
    -202 => 'Missing configuration file',
    -203 => 'Configuration file invalid',
    -204 => 'Configuration incomplete',

    # Logging errors
    -300 => 'Logging error',
    -301 => 'Logging initialization failed',
    -302 => 'Logging file creation failed',
    -303 => 'Logging file write failed',

    # Persistence errors
    -400 => 'Persistence error',
    -401 => 'Database error',
    -402 => 'File error',
    -403 => 'Data corrupt',
    -404 => 'No data found',
    -405 => 'Invalid data',

    # Core errors
    -500 => 'Core error',
    -501 => 'Core initialization failed',
    -502 => 'Core operation failed',

    # License errors
    -700 => 'License error',
    -701 => 'Invalid license',
    -702 => 'License expired',
    -703 => 'License not found',
    -704 => 'License download failed',
    -705 => 'License verification failed',
    -706 => 'Feature not licensed',
    -707 => 'Terminal not licensed',
    -708 => 'License limit exceeded',

    # Handle errors
    -1_000 => 'Invalid handle',
    -1_001 => 'Null handle',
    -1_002 => 'Handle not found',
    -1_003 => 'Handle type mismatch',
    -1_004 => 'Handle creation failed',

    # Option list errors
    -1_100 => 'Option list error',
    -1_101 => 'Option element not found',
    -1_102 => 'Option type mismatch',
    -1_103 => 'Invalid option key',
    -1_104 => 'Option list empty',
    -1_105 => 'Duplicate option key',
    -1_106 => 'Option list operation failed',

    # Instance errors
    -1_200 => 'Instance error',
    -1_201 => 'Instance creation failed',
    -1_202 => 'Instance not configured',
    -1_203 => 'Instance invalid state',
    -1_204 => 'Operation pending',
    -1_205 => 'Instance not open',
    -1_206 => 'Instance already open',
    -1_207 => 'Instance configuration error',
    -1_208 => 'Instance callback error',

    # State machine errors
    -1_300 => 'State machine error',
    -1_301 => 'Invalid state transition',
    -1_302 => 'Operation not allowed',
    -1_303 => 'State machine timeout',
    -1_304 => 'Operation aborted',

    # Card type errors
    -1_400 => 'Card type error',
    -1_401 => 'Card type not found',
    -1_402 => 'Card type configuration error',

    # Communication errors
    -1_500 => 'Communication error',
    -1_501 => 'Connection failed',
    -1_502 => 'Disconnected',
    -1_503 => 'Communication timeout',
    -1_504 => 'Send error',
    -1_505 => 'Receive error',
    -1_506 => 'Protocol error',
    -1_507 => 'Invalid response',
    -1_508 => 'Terminal busy',
    -1_509 => 'Terminal error',
);

sub checkResult($self, $result, $context) {
    if(!defined $result) {
        croak("Undefined result code in context: $context");
    }

    if($result >= PEP_FUNCTION_RESULT_SUCCESS) {
        return 1;
    }

    my $message = $ERROR_MESSAGES{$result} || "Unknown error code: $result";
    my $fullMessage = $context ? "$context: $message (code: $result)" : "$message (code: $result)";

    croak($fullMessage);
}

sub getErrorMessage($self, $result) {
    return $ERROR_MESSAGES{$result} || "Unknown error code: $result";
}

sub isSuccess($self, $result) {
    return defined($result) && $result >= PEP_FUNCTION_RESULT_SUCCESS;
}

sub isFailure($self, $result) {
    return !defined($result) || $result < PEP_FUNCTION_RESULT_SUCCESS;
}

1;

__END__

=head1 NAME

Lib::Pepper::Exception - Error handling and exception management for Lib::Pepper

=head1 SYNOPSIS

    use Lib::Pepper::Exception;
    use Lib::Pepper::Constants qw(:errors);

    # Check result and throw exception on failure
    Lib::Pepper::Exception->checkResult($result, 'pepInitialize');

    # Get error message for a result code
    my $message = Lib::Pepper::Exception->getErrorMessage($result);

    # Check if result indicates success
    if(Lib::Pepper::Exception->isSuccess($result)) {
        print "Operation successful\n";
    }

    # Check if result indicates failure
    if(Lib::Pepper::Exception->isFailure($result)) {
        print "Operation failed\n";
    }

=head1 DESCRIPTION

This module provides error handling and exception management for the Lib::Pepper
payment terminal library. It maps Pepper error codes to human-readable messages
and provides methods for checking results and throwing exceptions.

=head1 METHODS

=head2 checkResult($result, $context)

Checks if a result code indicates success. If the result indicates failure,
throws an exception using croak() with a descriptive error message.

    Lib::Pepper::Exception->checkResult($result, 'Operation name');

Parameters:
- $result: The PEPFunctionResult code to check
- $context: Optional context string to include in error message

Throws: Exception via croak() if result indicates failure

=head2 getErrorMessage($result)

Returns a human-readable error message for the given result code.

    my $message = Lib::Pepper::Exception->getErrorMessage(-103);
    # Returns: "Library not initialized"

Parameters:
- $result: The PEPFunctionResult code

Returns: String containing the error message

=head2 isSuccess($result)

Checks if a result code indicates success (>= 0).

    if(Lib::Pepper::Exception->isSuccess($result)) {
        # Handle success
    }

Parameters:
- $result: The PEPFunctionResult code to check

Returns: True if success, false otherwise

=head2 isFailure($result)

Checks if a result code indicates failure (< 0).

    if(Lib::Pepper::Exception->isFailure($result)) {
        # Handle failure
    }

Parameters:
- $result: The PEPFunctionResult code to check

Returns: True if failure, false otherwise

=head1 ERROR CODES

This module recognizes all standard Pepper error codes, organized into categories:

=head2 Generic Errors (-1 to -5)

- -1: Generic failure
- -2: Invalid value provided
- -3: Invalid state
- -4: Functionality not licensed
- -5: Out of memory

=head2 Library Errors (-100 to -106)

- -100: Library initialization failed
- -101: Library already initialized
- -102: Library loading error
- -103: Library not initialized
- -104: Library version mismatch
- -105: Library dependency error
- -106: Library still in use

=head2 Configuration Errors (-200 to -204)

- -200: Configuration error
- -201: Invalid configuration
- -202: Missing configuration file
- -203: Configuration file invalid
- -204: Configuration incomplete

=head2 Communication Errors (-1500 to -1509)

- -1500: Communication error
- -1501: Connection failed
- -1502: Disconnected
- -1503: Communication timeout
- -1504: Send error
- -1505: Receive error
- -1506: Protocol error
- -1507: Invalid response
- -1508: Terminal busy
- -1509: Terminal error

See Lib::Pepper::Constants for the complete list of error code constants.

=head1 WARNING: AI USE

Warning, this file was generated with the help of the 'Claude' AI (an LLM/large
language model by the USA company Anthropic PBC) in November 2025. It was not
reviewed line-by-line by a human, only on a functional level. It is therefore
not up to the usual code quality and review standards. Different copyright laws
may also apply, since the program was not created by humans but mostly by a machine,
therefore the laws requiring a human creative process may or may not apply. Laws
regarding AI use are changing rapidly. Before using the code provided in this
file for any of your projects, make sure to check the current version of your
local laws.

=head1 AUTHOR

Rene Schickbauer, E<lt>cavac@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2025 by Rene Schickbauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.42.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
