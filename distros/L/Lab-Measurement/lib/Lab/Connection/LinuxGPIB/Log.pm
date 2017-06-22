package Lab::Connection::LinuxGPIB::Log;
$Lab::Connection::LinuxGPIB::Log::VERSION = '3.550';
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

with 'Lab::Connection::Log';

1;

