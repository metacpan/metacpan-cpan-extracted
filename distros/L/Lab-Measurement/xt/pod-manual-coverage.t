#!/usr/bin/env perl

# Ensure that Lab::Measurement::Manual contains links to all of our modules.
use 5.010;
use warnings;
use strict;
use File::Slurper 'read_binary';
use File::Find;
use Data::Dumper;
use Test::More;

my $manual = read_binary('lib/Lab/Measurement/Manual.pod');

my @module_links = $manual =~ /L<(Lab::.*?)>/g;

# Create lookup table
my %module_links = map { $_ => 1 } @module_links;
# print Dumper \%module_links;
my @source_files;

find(
    {
        wanted => sub {
            my $file = $_;
            if ( $file =~ /\.(pm|pod)$/ ) {
                push @source_files, $file;
            }
        },
        no_chdir => 1,
    },
    'lib'
);

my %source_files = map {
    my $file = $_;
    $file =~ s{^lib/}{};
    $file =~ s{\.(pm|pod)$}{};
    $file =~ s{/}{::}g;
    ( $file => $_ );
} @source_files;

# The following legacy modules are not required in the manual
my @whitelist = qw/
    Lab::Measurement::Manual

    Lab::Moose::Connection::VISA_GPIB
    Lab::Moose::Instrument::OI_IPS::Strunk_3He
    Lab::Moose::Sweep::DataFile

    Lab::MultiChannelInstrument
    Lab::GenericSignals
    Lab::Generic
    Lab::Exception
    Lab::Generic::CLOptions
    Lab::Bus::VICP
    Lab::Bus::Socket

    Lab::Data::Analysis
    Lab::Data::Analysis::TekTDS
    Lab::Data::Analysis::WaveRunner

    Lab::Connection::Mock
    Lab::Connection::VICP
    Lab::Connection::LogMethodCall
    Lab::Connection::Trace
    Lab::Connection::TCPraw
    Lab::Connection::Log
    Lab::Connection::VICP::Trace
    Lab::Connection::Socket
    Lab::Connection::Socket::Trace
    Lab::Connection::DEBUG
    Lab::Connection::DEBUG::Trace
    Lab::Connection::DEBUG::Log
    Lab::Connection::USBtmc::Trace
    Lab::Connection::VISA_GPIB::Trace
    Lab::Connection::VISA_GPIB::Log
    Lab::Connection::LinuxGPIB::Trace
    Lab::Connection::LinuxGPIB::Log

    Lab::Measurement
    Lab::Measurement::Legacy::Developer::Write-A-Source-Driver
    Lab::Measurement::Legacy::Tutorial
    Lab::Measurement::Legacy::Developer::Testing
    Lab::Measurement::KeyboardHandling
    Lab::MultiChannelInstrument::DeviceCache

    Lab::SCPI

    Lab::XPRESS::Data::XPRESS_plotter
    Lab::XPRESS::Data::XPRESS_logger
    Lab::XPRESS::Data::XPRESS_DataFile
    Lab::XPRESS::Examples::Example1_Simple_IV
    Lab::XPRESS::Examples::Example2_Gate_IV_scan
    Lab::XPRESS::Examples::Example3_2samples_2files
    Lab::XPRESS::Examples::Example4_3d_scan
    Lab::XPRESS::hub
    Lab::XPRESS::Sweep
    Lab::XPRESS::Sweep::Frame
    Lab::XPRESS::Sweep::Magnet
    Lab::XPRESS::Sweep::Voltage
    Lab::XPRESS::Sweep::Time
    Lab::XPRESS::Sweep::Motor
    Lab::XPRESS::Sweep::Repeater
    Lab::XPRESS::Sweep::Temperature
    Lab::XPRESS::Sweep::PulseLength
    Lab::XPRESS::Sweep::Amplitude
    Lab::XPRESS::Sweep::Level
    Lab::XPRESS::Sweep::LogBlock
    Lab::XPRESS::Sweep::SignalRecoveryPhase
    Lab::XPRESS::Sweep::SignalRecoveryOscOut
    Lab::XPRESS::Sweep::PulsePeriod
    Lab::XPRESS::Sweep::SweepND
    Lab::XPRESS::Sweep::Frequency
    Lab::XPRESS::Sweep::DietersCrazyTempSweep
    Lab::XPRESS::Sweep::VM_DIR
    Lab::XPRESS::Sweep::Dummy
    Lab::XPRESS::Sweep::Power
    Lab::XPRESS::Utilities::Utilities

    Lab::Instrument
    Lab::Instrument::Multimeter
    Lab::Instrument::HP34401A
    Lab::Instrument::HP34420A
    Lab::Instrument::HP3458A
    Lab::Instrument::Agilent34410A
    Lab::Instrument::Keithley2000
    Lab::Instrument::Source
    Lab::Instrument::DummySource
    Lab::Instrument::Yokogawa7651
    Lab::Instrument::YokogawaGS200
    Lab::Instrument::Keithley2400
    Lab::Instrument::SR830
    Lab::Instrument::SR830::AuxIn
    Lab::Instrument::SR830::AuxOut
    Lab::Instrument::SignalRecovery726x
    Lab::Instrument::HP33120A
    Lab::Instrument::HP83732A
    Lab::Instrument::MG369xB
    Lab::Instrument::U2000
    Lab::Instrument::TDS2024B
    Lab::Instrument::WR640
    Lab::Instrument::IPS
    Lab::Instrument::TRMC2
    Lab::Instrument::OI_ITC503
    Lab::Instrument::ITC
    Lab::Instrument::TCD
    Lab::Instrument::OI_Triton
    Lab::Instrument::TemperatureControl::TLK43
    Lab::Instrument::Lakeshore33x
    Lab::Instrument::Lakeshore340
    Lab::Instrument::OI_ILM210
    Lab::Instrument::PD11042
    Lab::Instrument::OI_IPS
    Lab::Instrument::MagnetSupply
    Lab::Instrument::TemperatureDiode
    Lab::Instrument::TemperatureDiode::RO600
    Lab::Instrument::TemperatureDiode::SI420
    Lab::Instrument::AH2700A
    Lab::Instrument::Agilent34420A
    Lab::Instrument::LabViewHeater
    Lab::Instrument::Vectormagnet
    Lab::Instrument::AgilentE8362A
    Lab::Instrument::Lakeshore224
    Lab::Instrument::IPSWeissDilfridge
    Lab::Instrument::ProStep4
    Lab::Instrument::Cryogenic_SMS
    Lab::Instrument::TemperatureControl

    Lab::Exception::Base
    Lab::Connection
    Lab::Bus
    Lab::Bus::DEBUG
    Lab::Connection::VISA
    Lab::Bus::VISA
    Lab::Connection::GPIB
    Lab::Connection::LinuxGPIB
    Lab::Connection::VISA_GPIB
    Lab::Bus::LinuxGPIB
    Lab::Connection::RS232
    Lab::Connection::VISA_RS232
    Lab::Bus::RS232
    Lab::Connection::USBtmc
    Lab::Bus::USBtmc
    Lab::Connection::IsoBus
    Lab::Bus::IsoBus
    Lab::Connection::MODBUS_RS232
    Lab::Bus::MODBUS_RS232

    /;

for my $white (@whitelist) {
    delete $source_files{$white};
}

diag("Checking for dead links in the manual");
for my $link ( keys %module_links ) {
    ok( exists $source_files{$link}, "source file for module $link exists" );
}

diag("Checking for L::M modules missing in the manual");
for my $source ( keys %source_files ) {
    ok( exists $module_links{$source}, "have link to $source" );
}

diag("Checking for modules without pod");
for my $source ( keys %source_files ) {
    my $file     = $source_files{$source};
    my $contents = read_binary($file);
    like( $contents, qr/^=head1/m, "$file contains pod" );
}

done_testing();
