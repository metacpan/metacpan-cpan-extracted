use warnings;
use strict;
use Test::Most 0.38;
use File::Temp qw(tempfile);
use Set::Tiny 0.04;

plan tests => 27;

require_ok('Linux::Info::DiskStats::Options');

my @methods = (
    'get_init_file',            'get_source_file',
    'get_backwards_compatible', 'get_global_block_size',
    'get_block_sizes',          'get_current_kernel'
);

can_ok( 'Linux::Info::DiskStats::Options', @methods );

dies_ok { Linux::Info::DiskStats::Options->new( [] ) }
'dies with wrong options reference';
like $@, qr/hash\sreference/, 'got expected error message';

dies_ok { Linux::Info::DiskStats::Options->new() }
'dies without global_block_size';
like $@, qr/block_size/, 'got expected error message';

dies_ok { Linux::Info::DiskStats::Options->new( { foo => 'bar' } ) }
'dies with invalid configuration key';
like $@, qr/is\snot\svalid/, 'got expected error message';

ok(
    Linux::Info::DiskStats::Options->new( { backwards_compatible => 0 } ),
    'get instance with backwards_compatible disabled and without block sizes'
);

note('Testing with backwards compatibility');
dies_ok {
    Linux::Info::DiskStats::Options->new( { global_block_size => 4.34 } )
}
'dies with invalid value for global_block_size';
like $@, qr/integer\sas\svalue/, 'got expected error message';

dies_ok {
    Linux::Info::DiskStats::Options->new( { block_sizes => '' } )
}
'dies with invalid value for block_sizes';
like $@, qr/hash\sreference/, 'got expected error message';

dies_ok {
    Linux::Info::DiskStats::Options->new( { block_sizes => {} } )
}
'dies with invalid value for the block_sizes hash reference';
like $@, qr/at\sleast\sone\sdisk/, 'got expected error message';

dies_ok {
    Linux::Info::DiskStats::Options->new( { block_sizes => { sda => '' } } )
}
'dies with invalid value for block size in block_sizes disk';
like $@, qr/must\sbe\san\sinteger/, 'got expected error message';

ok( Linux::Info::DiskStats::Options->new( { global_block_size => 4096 } ),
    'get instance with proper global_block_size' );
ok(
    Linux::Info::DiskStats::Options->new( { block_sizes => { sda => 4096 } } ),
    'get instance with proper block_sizes'
);

test_file('source_file');
test_file('init_file');

my ( $fh, $filename ) = tempfile();
close($fh) or diag("Failed to close $filename: $!");

ok(
    Linux::Info::DiskStats::Options->new(
        {
            source_file          => $filename,
            backwards_compatible => 0,
            current_kernel       => '2.6.18-0-generic'
        }
    ),
    'works fine with existing source'
);

my $instance = Linux::Info::DiskStats::Options->new(
    {
        source_file          => $filename,
        backwards_compatible => 0,
        current_kernel       => '2.6.18-0-generic'
    }
);

isa_ok(
    $instance,
    'Linux::Info::DiskStats::Options',
    'new returns the expected class instance'
);
is( $instance->get_current_kernel->get_minor,
    6, 'fetches the correct minor number of a given kernel release' );

my $block_size = 4096;
$instance = Linux::Info::DiskStats::Options->new(
    {
        source_file          => $filename,
        backwards_compatible => 1,
        current_kernel       => '2.6.18-0-generic',
        global_block_size    => $block_size,
    }
);

is( $instance->get_global_block_size,
    $block_size, 'get_global_block_size returns the expected value' );
unlink $filename or diag("Failed to remove $filename: $!");

sub test_file {
    my $source_file_key = shift;
    my ( $fh, $filename ) = tempfile();
    close($fh)       or diag("Failed to close $filename: $!");
    unlink $filename or diag("Failed to remove $filename: $!");

    dies_ok {
        Linux::Info::DiskStats::Options->new(
            { $source_file_key => $filename, backwards_compatible => 0 } )
    }
    "'$source_file_key' dies with non-existing file";
    like $@, qr/does\snot\sexist\s/, 'got expected error message';
}
