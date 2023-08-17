package Lab::Exception;
$Lab::Exception::VERSION = '3.881';
#ABSTRACT: Exception handling classes

use v5.20;

no strict; # FIXME

#
# un/comment the following BEGIN clause to slap in the custom base class above
#
BEGIN { $Exception::Class::BASE_EXC_CLASS = 'Lab::Exception::Base'; }

use Exception::Class (

    Lab::Exception::Error => {
        description => 'An error.',
    },

    #
    # general errors
    #
    Lab::Exception::CorruptParameter => {
        isa => 'Lab::Exception::Error',
        description =>
            "A provided method parameter was of wrong type or otherwise corrupt.",
        fields => [
            'invalid_parameter',    # put the invalid parameter here
        ],
    },

    Lab::Exception::Timeout => {
        isa => 'Lab::Exception::Error',
        description =>
            "A timeout occured. If any data was received nontheless, you can read it off this exception object if you care for it.",
        fields => [
            'data'
            , # this is meant to contain the data that (maybe) has been read/obtained/generated despite and up to the timeout.
        ],
    },

    Lab::Exception::Unimplemented => {
        description => 'An unimplemented method has been called.',
    },

    #
    # Driver level errors
    #
    Lab::Exception::DriverError => {
        isa => 'Lab::Exception::Error',
        description =>
            'Something went wrong in the Instrument driver regime.',
        fields => [],
    },

    #
    # errors and warnings specific to Lab::Connection::GPIB
    #
    Lab::Exception::GPIBError => {
        isa => 'Lab::Exception::Error',
        description =>
            'An error occured in the GPIB connection (linux-gpib).',
        fields => [
            'ibsta',    # the raw ibsta status byte received from linux-gpib
            'ibsta_hash'
            , # the ibsta bit values in a named, easy-to-read hash ( 'DCAS' => $val, 'DTAS' => $val, ...
              # use Lab::Connection::GPIB::VerboseIbstatus() to get a nice string representation
        ],
    },

    Lab::Exception::GPIBTimeout => {
        isa => 'Lab::Exception::GPIBError',
        description =>
            'A timeout occured in the GPIB connection (linux-gpib).',
        fields => [
            'data'
            , # this is meant to contain the data that (maybe) has been read/obtained/generated despite and up to the timeout.
        ],
    },

    #
    # errors and warnings specific to VISA / Lab::VISA
    #

    Lab::Exception::VISAError => {
        isa => 'Lab::Exception::Error',
        description =>
            'An error occured with NI VISA or the Lab::VISA interface',
        fields => [
            'status',    # the status returned from Lab::VISA, if any
        ],
    },

    Lab::Exception::VISATimeout => {
        isa => 'Lab::Exception::VISAError',
        description =>
            'A timeout occured while reading/writing through NI VISA / Lab::VISA',
        fields => [
            'status',     # the status returned from Lab::VISA, if any
            'command',    # the command that led to the timeout
            'data',       # the data read up to the abort
        ],
    },

    #
    # errors and warnings specific to RS232
    #

    Lab::Exception::RS232Error => {
        isa         => 'Lab::Exception::Error',
        description => 'An error occured with the native RS232 interface',
        fields      => [
            'status',    # the returned status
        ],
    },

    Lab::Exception::RS232Timeout => {
        isa => 'Lab::Exception::RS232Error',
        description =>
            'A timeout occured while reading/writing through native RS232 interface',
        fields => [
            'status',     # the status returned
            'command',    # the command that led to the timeout
            'data',       # the data read up to the abort
        ],
    },

    #
    # errors and warnings specific to USB TMC
    #

    Lab::Exception::TMCOpenFileError => {
        isa => 'Lab::Exception::Error',
        description =>
            'An error occured while trying to open the device file',
        fields => [],
    },

    #
    # errors and warnings sent by devices
    #

    Lab::Exception::DeviceError => {
        isa         => 'Lab::Exception::Error',
        description => "A device has reported one or more errors.",
        fields      => [
            'device_class',    # driver class of the device
            'command',         # last command as (and if) given by the script
            'raw_message',     # raw received error response (if useful)
            'error_list'
            , # list of errors, of the format [ [$errcode1, $errmsg1], [$errcode2, $errmsg2]. ... ]
        ],
    },

    #
    # general warnings
    #
    Lab::Exception::Warning => { description => 'A warning.' },

    Lab::Exception::UndefinedField => {
        isa         => 'Lab::Exception::Warning',
        description => "AUTOLOAD couldn't find requested field in object",
    },
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Exception - Exception handling classes

=head1 VERSION

version 3.881

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by the Lab::Measurement team; in detail:

  Copyright 2011       Andreas K. Huettel, Florian Olbrich
            2012       Alois Dirnaichner, Andreas K. Huettel, Florian Olbrich, Hermann Kraus
            2014       Andreas K. Huettel
            2016       Simon Reinhardt
            2017       Andreas K. Huettel
            2019       Simon Reinhardt
            2020       Andreas K. Huettel


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
