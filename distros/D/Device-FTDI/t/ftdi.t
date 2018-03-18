use Test::More 0.94;
use Device::FTDI qw(:all);

subtest Constants => sub {
    is PARITY_NONE,  0, 'NONE';
    is PARITY_ODD,   1, 'ODD';
    is PARITY_EVEN,  2, 'EVEN';
    is PARITY_MARK,  3, 'MARK';
    is PARITY_SPACE, 4, 'SPACE';
};

subtest Device => sub {
    plan skip_all => "Define ALLOW_ACCESS_TO_FTDI_DEVICE variable"
      unless $ENV{ALLOW_ACCESS_TO_FTDI_DEVICE};
    my $dev = eval { Device::FTDI->new };
    plan skip_all => "Couldn't open FTDI device" unless $dev;
    isa_ok $dev, 'Device::FTDI';

    $dev->setflowctrl(FLOW_RTS_CTS);
    $dev->setflowctrl(FLOW_DTR_DSR);
    $dev->setflowctrl(FLOW_XON_XOFF);
    $dev->setflowctrl(FLOW_DISABLE);
    $dev->set_line_property( BITS_8, STOP_BIT_15, PARITY_NONE, BREAK_OFF );
    $dev->set_baudrate(115200);
    $dev->set_latency_timer(100);
    is $dev->get_latency_timer, 100, "latency set to 100";
    $dev->write_data_set_chunksize(16);
    is $dev->write_data_get_chunksize, 16, "write data chunksize is 16";
    $dev->read_data_set_chunksize(16);
    is $dev->read_data_get_chunksize, 16, "read data chunksize is 16";

    $dev->purge_rx_buffer;
    $dev->purge_tx_buffer;
    $dev->purge_buffers;

    $dev->write_data("#SSSS\r");
    my $len = $dev->read_data( my $buf, 128 );
};

done_testing;
