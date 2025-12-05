package Lib::Pepper;
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


use File::Spec;
use File::Basename;

use parent 'Exporter';

our @EXPORT_OK = qw(
    pepInitialize
    pepFinalize
    pepVersion
    pepCreateInstance
    pepFreeInstance
    pepConfigureWithCallback
    pepPrepareOperation
    pepStartOperation
    pepExecuteOperation
    pepFinalizeOperation
    pepOperationStatus
    pepUtility
    pepAuxiliary
    pepDownloadLicense
    pepOptionListCreate
    pepOptionListGetStringElement
    pepOptionListGetIntElement
    pepOptionListGetChildOptionListElement
    pepOptionListAddStringElement
    pepOptionListAddIntElement
    pepOptionListAddChildOptionListElement
    pepOptionListGetElementList
    isValidHandle
    isSuccess
    isFailure
);

our %EXPORT_TAGS = (
    all => \@EXPORT_OK,
);

require XSLoader;
XSLoader::load('Lib::Pepper', $VERSION);

# Library initialization wrapper with better error handling
sub initialize($class, %params) {
    my $libPath = $params{library_path} || '';
    my $configXml = $params{config_xml};
    my $licenseXml = $params{license_xml};

    my ($result, $terminalTypeList) = pepInitialize($libPath, $configXml, $licenseXml);

    if($result < 0) {
        croak("Library initialization failed with code: $result");
    }

    return $terminalTypeList;
}

# Library finalization wrapper
sub finalize($class) {
    my $result = pepFinalize();

    if($result < 0) {
        croak("Library finalization failed with code: $result");
    }

    return 1;
}

# Get version information
sub version($class) {
    my ($result, $major, $minor, $service, $revision, $api, $osArch, $releaseType, $configType) = pepVersion();

    if($result < 0) {
        croak("Version query failed with code: $result");
    }

    return {
        major       => $major,
        minor       => $minor,
        service     => $service,
        revision    => $revision,
        api         => $api,
        osArch      => $osArch,
        releaseType => $releaseType,
        configType  => $configType,
        string      => "$major.$minor.$service.$revision",
    };
}

# Get the installation directory for library data files
sub dataDir($class) {
    # Try to find the installed data directory
    # Data files are installed alongside shared libraries in auto/Lib/Pepper/

    # Method 1: Check installed location (after 'make install')
    foreach my $inc (@INC) {
        my $dataDir = File::Spec->catdir($inc, 'auto', 'Lib', 'Pepper');
        if(-d $dataDir && -f File::Spec->catfile($dataDir, 'pepper_cardtypes.xml')) {
            return $dataDir;
        }
    }

    # Method 2: Check development location (for testing before install)
    # Look for share/ directory relative to this module's location
    # Module is at lib/Lib/Pepper.pm, share/ is at share/
    my $module_path = $INC{'Lib/Pepper.pm'};
    if(defined $module_path) {
        require File::Basename;
        require Cwd;
        my $moduleDir = File::Basename::dirname($module_path);  # lib/Lib
        my $projectRoot = Cwd::abs_path(File::Spec->catdir($moduleDir, '..', '..'));  # Go up to project root
        my $devShare = File::Spec->catdir($projectRoot, 'share');
        if(-d $devShare && -f File::Spec->catfile($devShare, 'pepper_cardtypes.xml')) {
            return $devShare;
        }
    }

    # Not found
    return;
}

# Get the path to the installed pepper_cardtypes.xml file
sub cardtypesFile($class) {
    my $dataDir = $class->dataDir();
    return unless defined $dataDir;

    my $cardtypesPath = File::Spec->catfile($dataDir, 'pepper_cardtypes.xml');
    return -f $cardtypesPath ? $cardtypesPath : undef;
}

1;
__END__

=head1 NAME

Lib::Pepper - Perl bindings for the Pepper payment terminal library

=head1 SYNOPSIS

    use Lib::Pepper;
    use Lib::Pepper::Constants qw(:all);
    use Lib::Pepper::OptionList;
    use Lib::Pepper::Instance;

    # Initialize the library
    Lib::Pepper->initialize(
        library_path => '',  # Empty for default
    );

    # Get version information
    my $version = Lib::Pepper->version();
    print "Pepper version: $version->{string}\n";

    # Create an instance for a payment terminal
    my $instance = Lib::Pepper::Instance->new(
        terminal_type => PEP_TERMINAL_TYPE_MOCK,  # Or GENERIC_ZVT, HOBEX_ZVT
        instance_id => 1,
    );

    # Configure the instance
    $instance->configure(
        callback => sub {
            my ($event, $option, $instanceHandle, $outputOptions, $inputOptions, $userData) = @_;
            # Handle callback events
        },
        options => {
            sHostName => '192.168.1.100:20007',
            iLanguageValue => PEP_LANGUAGE_ENGLISH,
        },
    );

    # Perform a transaction
    my $result = $instance->transaction(
        transaction_type => PEP_TRANSACTION_TYPE_GOODS_PAYMENT,
        amount => 10_050,  # 100.50 EUR in cents
        currency => PEP_CURRENCY_EUR,
    );

    # Clean up
    $instance = undef;
    Lib::Pepper->finalize();

=head1 DESCRIPTION

Lib::Pepper provides Perl bindings for the Pepper payment terminal library,
which supports ZVT (Zentraler Kreditausschuss Terminal) protocol communication
with EFT/POS payment terminals.

This module provides both low-level XS bindings to the C API and high-level
object-oriented wrappers for ease of use.

In all likelyhood, you really want to use the simplified bindings in L<Lib::Pepper::Simple>, not the low level stuff.

=head2 FEATURES

- Support for Generic ZVT (Terminal Type 118) and Hobex ZVT (Terminal Type 120)
- Asynchronous callback-based operation
- Complete API coverage (initialization, configuration, transactions, settlements)
- Object-oriented interface with Lib::Pepper::Instance
- Option list management with Lib::Pepper::OptionList
- Comprehensive error handling with Lib::Pepper::Exception
- 200+ exported constants for operations, currencies, and error codes

=head1 METHODS

=head2 initialize(%params)

Initializes the Pepper library. Must be called before any other operations.

    Lib::Pepper->initialize(
        library_path => '',           # Optional: path to libpepcore.so
        config_xml   => undef,        # Optional: XML configuration string
        license_xml  => undef,        # Optional: XML license string
    );

Parameters:
- library_path: Optional path to pepcore library (empty for default)
- config_xml: Optional XML configuration (undef to use config file)
- license_xml: Optional XML license (undef to use license file)

Returns: Terminal type option list handle

Throws: Exception on failure

=head2 finalize()

Finalizes and cleans up the Pepper library. Call when done with all operations.

    Lib::Pepper->finalize();

Returns: 1 on success

Throws: Exception on failure

=head2 version()

Returns version information about the Pepper library.

    my $version = Lib::Pepper->version();
    print "Version: $version->{string}\n";
    print "API version: $version->{api}\n";

Returns: Hashref with keys: major, minor, service, revision, api, osArch,
         releaseType, configType, string

=head1 UTILITY METHODS

=head2 dataDir()

Returns the installation directory containing library data files.

    my $dir = Lib::Pepper->dataDir();

Searches for the data directory in two locations:

1. Installed location: C<$PREFIX/lib/perl5/auto/Lib/Pepper/>
2. Development location: C<share/> relative to module path

Returns: Directory path as string, or undef if not found

=head2 cardtypesFile()

Returns the full path to the installed pepper_cardtypes.xml file.

    my $path = Lib::Pepper->cardtypesFile();

This file contains card type definitions and is required for terminal configuration.
Use the returned path in your config XML or pass it to configuration methods.

Returns: File path as string, or undef if not found

=head1 LOW-LEVEL FUNCTIONS

The following low-level XS functions are available for direct use.
They can be imported individually or with C<:all> tag.

B<NOTE>: Most users should use L<Lib::Pepper::Instance> or L<Lib::Pepper::Simple>
instead of these low-level functions.

=head2 Library Management

=head3 pepInitialize($libraryPath, $configXml, $licenseXml)

Initializes the Pepper payment library.

    my $result = pepInitialize($libPath, $configXml, $licenseXml);

Parameters:

=over 4

=item $libraryPath - Path to libpepcore.so (or empty string for installed library)

=item $configXml - Configuration XML content as string

=item $licenseXml - License XML content as string

=back

Returns: Result code (0 = success, negative = error)

=head3 pepFinalize()

Finalizes and shuts down the Pepper library.

    my $result = pepFinalize();

Call this when completely done with the library.
Frees all library resources.

Returns: Result code (0 = success, negative = error)

=head3 pepVersion()

Queries the Pepper library version information.

    my ($result, $major, $minor, $service, $revision, $api,
        $osArch, $releaseType, $configType) = pepVersion();

Returns: List of version components

=head2 Instance Management

=head3 pepCreateInstance($terminalType, $instanceId)

Creates a new Pepper instance for a payment terminal.

    my ($result, $handle) = pepCreateInstance($termType, $id);

Parameters:

=over 4

=item $terminalType - Terminal type constant (e.g., PEP_TERMINAL_TYPE_GENERIC_ZVT)

=item $instanceId - Unique instance identifier string

=back

Returns: ($result, $handle) - Result code and instance handle

=head3 pepFreeInstance($instance)

Frees a Pepper instance.

    my $result = pepFreeInstance($handle);

Releases all resources associated with the instance.

Returns: Result code

=head3 pepConfigureWithCallback($instance, $inputOptions, $callback, $userData)

Configures an instance with callback and options.

    my ($result, $outputOptions) = pepConfigureWithCallback(
        $handle, $optionList, \&callback, $userData
    );

Parameters:

=over 4

=item $instance - Instance handle

=item $inputOptions - Option list handle with configuration

=item $callback - Code reference for event callbacks

=item $userData - Custom data passed to callbacks

=back

Returns: ($result, $outputOptions) - Result code and output option list handle

=head2 Operation Workflow

All operations follow a 4-step workflow: prepare, start, execute, finalize.

=head3 pepPrepareOperation($instance, $operation, $inputOptions)

Executes the "prepare" step of an operation.

    my ($result, $opHandle, $outputOptions) = pepPrepareOperation(
        $instance, PEP_OPERATION_TRANSACTION, $optionList
    );

Parameters:

=over 4

=item $instance - Instance handle

=item $operation - Operation type constant

=item $inputOptions - Option list handle with operation parameters

=back

Returns: ($result, $operationHandle, $outputOptions)

=head3 pepStartOperation($instance, $operation, $inputOptions)

Executes the "start" step of an operation.

    my ($result, $opHandle, $outputOptions) = pepStartOperation(
        $instance, $operation, $optionList
    );

See pepPrepareOperation for parameter details.

=head3 pepExecuteOperation($instance, $operation, $inputOptions)

Executes the "execute" step of an operation.

    my ($result, $opHandle, $outputOptions) = pepExecuteOperation(
        $instance, $operation, $optionList
    );

See pepPrepareOperation for parameter details.

=head3 pepFinalizeOperation($instance, $operation, $inputOptions)

Executes the "finalize" step of an operation.

    my ($result, $opHandle, $outputOptions) = pepFinalizeOperation(
        $instance, $operation, $optionList
    );

See pepPrepareOperation for parameter details.

=head3 pepOperationStatus($instance, $operation, $waitForCompletion)

Checks the status of an operation.

    my ($result, $status) = pepOperationStatus($instance, $opHandle, 1);

Parameters:

=over 4

=item $instance - Instance handle

=item $operation - Operation handle

=item $waitForCompletion - Boolean: 1 to block until complete, 0 to return immediately

=back

Returns: ($result, $status) - Result code and completion status

=head2 Utilities

=head3 pepUtility($instance, $inputOptions)

Executes a utility operation (synchronous).

    my ($result, $outputOptions) = pepUtility($instance, $optionList);

Used for terminal utility functions like status queries, configuration changes.

Returns: ($result, $outputOptions)

=head3 pepAuxiliary($instance, $inputOptions)

Executes an auxiliary operation (synchronous).

    my ($result, $outputOptions) = pepAuxiliary($instance, $optionList);

Used for terminal-specific auxiliary functions.

Returns: ($result, $outputOptions)

=head3 pepDownloadLicense($inputOptions)

Downloads a license from the license server.

    my ($result, $outputOptions) = pepDownloadLicense($optionList);

Requires license server credentials in input options.

Returns: ($result, $outputOptions)

=head2 Option Lists

Option lists are key-value containers for parameters and results.
See L<Lib::Pepper::OptionList> for object-oriented interface.

=head3 pepOptionListCreate()

Creates a new option list.

    my $handle = pepOptionListCreate();

Returns: Option list handle

=head3 pepOptionListGetStringElement($list, $key)

Retrieves a string value from an option list.

    my ($result, $value) = pepOptionListGetStringElement($list, $key);

Returns: ($result, $value)

=head3 pepOptionListGetIntElement($list, $key)

Retrieves an integer value from an option list.

    my ($result, $value) = pepOptionListGetIntElement($list, $key);

Returns: ($result, $value)

=head3 pepOptionListGetChildOptionListElement($list, $key)

Retrieves a child option list from an option list.

    my ($result, $childList) = pepOptionListGetChildOptionListElement($list, $key);

Returns: ($result, $childHandle)

=head3 pepOptionListAddStringElement($list, $key, $value)

Adds a string value to an option list.

    my $result = pepOptionListAddStringElement($list, $key, $value);

Returns: Result code

=head3 pepOptionListAddIntElement($list, $key, $value)

Adds an integer value to an option list.

    my $result = pepOptionListAddIntElement($list, $key, $value);

Returns: Result code

=head3 pepOptionListAddChildOptionListElement($list, $key, $childList)

Adds a child option list to an option list.

    my $result = pepOptionListAddChildOptionListElement($list, $key, $childList);

Returns: Result code

=head3 pepOptionListGetElementList($list)

Retrieves all keys from an option list.

    my ($result, @keys) = pepOptionListGetElementList($list);

Returns: ($result, @keys)

=head2 Helper Functions

=head3 isValidHandle($handle)

Checks if a handle is valid.

    if(isValidHandle($handle)) {
        # Handle is valid
    }

Returns: 1 if valid, 0 if invalid

=head3 isSuccess($result)

Checks if a result code indicates success.

    if(isSuccess($result)) {
        # Operation succeeded
    }

Returns: 1 if success, 0 if failure

=head3 isFailure($result)

Checks if a result code indicates failure.

    if(isFailure($result)) {
        # Operation failed
    }

Returns: 1 if failure, 0 if success

=head1 MODULES

=over 4

=item L<Lib::Pepper::Constants>

Exports 200+ constants for operations, states, currencies, error codes

=item L<Lib::Pepper::Exception>

Error handling and exception management

=item L<Lib::Pepper::OptionList>

Object-oriented wrapper for option lists

=item L<Lib::Pepper::Instance>

High-level instance management

=item L<Lib::Pepper::ZVT::Generic>

Helpers for Generic ZVT terminals (Type 118)

=item L<Lib::Pepper::ZVT::Hobex>

Helpers for Hobex ZVT terminals (Type 120)

=back

=head1 EXPORT

None by default. Functions can be imported individually or with the C<:all> tag.

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

=head1 SEE ALSO

Pepper Developer Documentation (included in pepperlib)

Examples directory in this package

L<Lib::Pepper::Simple>

ZVT Protocol Documentation

=head1 AUTHOR

Rene Schickbauer, E<lt>cavac@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2025 by Rene Schickbauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.42.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
