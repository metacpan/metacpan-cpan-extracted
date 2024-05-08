use strict;
use warnings;
use Test::Most tests => 504;
use Regexp::Common;
use Linux::Info::DiskStats::Options;

use constant KERNEL_INFO => 'kernel major version >= 6';

use lib './t/lib';
use Helpers qw(total_lines tests_set_desc);

require_ok('Linux::Info::DiskStats');

dies_ok { Linux::Info::DiskStats->new( {} ) }
'dies without a valid configuration';

my $opts = Linux::Info::DiskStats::Options->new(
    {
        source_file          => 't/samples/diskstatus-6.1.0-20.txt',
        backwards_compatible => 0,
        current_kernel       => '2.6.18-0-generic',
    }
);

note( tests_set_desc( $opts, KERNEL_INFO ) );

my $instance = Linux::Info::DiskStats->new($opts);

ok( $instance->init, 'calls init successfully' );
is( $instance->fields_read, 21,
    'got the expected number of fields read for ' . KERNEL_INFO );
is( ref $instance->raw, 'HASH', 'raw returns an hash reference' );

my $result_ref = $instance->get;
is( ref $result_ref, 'HASH', 'get returns an hash reference' );
is(
    scalar( keys( %{$result_ref} ) ),
    total_lines( $opts->get_source_file ),
    'Found all devices in the file'
);

bail_on_fail;

my $int_regex         = qr/$RE{num}->{int}/;
my $device_name_regex = qr/^\w+$/;
my %table             = (
    read_completed     => $int_regex,
    read_merged        => $int_regex,
    read_time          => $int_regex,
    write_completed    => $int_regex,
    write_merged       => $int_regex,
    sectors_written    => $int_regex,
    write_time         => $int_regex,
    io_in_progress     => $int_regex,
    io_time            => $int_regex,
    weighted_io_time   => $int_regex,
    discards_completed => $int_regex,
    discards_merged    => $int_regex,
    sectors_discarded  => $int_regex,
    discard_time       => $int_regex,
);

for my $device_name ( keys( %{$result_ref} ) ) {
    note("Testing the device $device_name values format");
    like( $device_name, $device_name_regex,
        'the device has an appropriated name' );
    is( ref $result_ref->{$device_name},
        'HASH', "information from $device_name is a hash reference" );
    for my $stat ( keys(%table) ) {
        ok( exists $result_ref->{$device_name}->{$stat}, "$stat is available" )
          or diag( explain( $result_ref->{$device_name} ) );
        like( $result_ref->{$device_name}->{$stat},
            $table{$stat}, "$stat has the expected value type" );
    }
}

my $device_name = 'sda';
note("Testing the device $device_name values");

my %expected = (
    read_completed     => 14683,
    read_merged        => 5170,
    sectors_read       => 1006894,
    read_time          => 6361,
    write_completed    => 5454,
    write_merged       => 4185,
    sectors_written    => 304914,
    write_time         => 5495,
    io_in_progress     => 0,
    io_time            => 13932,
    weighted_io_time   => 15164,
    discards_completed => 0,
    discards_merged    => 0,
    sectors_discarded  => 0,
    discard_time       => 0,
    flush_completed    => 2302,
    flush_time         => 3306,
);

for my $stat ( keys %expected ) {
    is( $result_ref->{$device_name}->{$stat},
        $expected{$stat}, "$stat provides the expected value" );
}
