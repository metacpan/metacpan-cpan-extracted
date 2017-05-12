#!perl

use warnings;
use strict;
use 5.010;

use lib 't';

use Lab::Test import => [qw/scpi_set_get_test/];
use Test::More;
use Moose::Instrument::MockTest qw/mock_instrument/;
use MooseX::Params::Validate;
use File::Spec::Functions 'catfile';
use Data::Dumper;

my $log_file = catfile(qw/t Moose Instrument RS_SMB.yml/);

my $smb = mock_instrument(
    type     => 'RS_SMB',
    log_file => $log_file,
);

# Test getters and setters

# Frequency

scpi_set_get_test(
    instr  => $smb,
    func   => 'source_frequency',
    values => [qw/1e5 1e6 1.1e9/],
);

# Power (Dbm)
scpi_set_get_test(
    instr  => $smb,
    func   => 'source_power_level_immediate_amplitude',
    values => [qw/10 -10 -20/],
);

$smb->rst();
done_testing();
