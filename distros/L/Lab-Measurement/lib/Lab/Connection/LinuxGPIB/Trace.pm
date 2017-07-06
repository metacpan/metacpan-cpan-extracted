package Lab::Connection::LinuxGPIB::Trace;
$Lab::Connection::LinuxGPIB::Trace::VERSION = '3.552';
use 5.010;
use warnings;
use strict;

use parent 'Lab::Connection::LinuxGPIB';

use Role::Tiny::With;
use Carp;
use autodie;

our %fields = (
    logfile   => undef,
    log_index => 0,
);

with 'Lab::Connection::Trace';

1;

