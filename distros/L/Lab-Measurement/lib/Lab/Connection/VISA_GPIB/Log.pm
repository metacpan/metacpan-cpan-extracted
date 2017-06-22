package Lab::Connection::VISA_GPIB::Log;
$Lab::Connection::VISA_GPIB::Log::VERSION = '3.550';
use 5.010;
use warnings;
use strict;

use parent 'Lab::Connection::VISA_GPIB';

use Role::Tiny::With;
use Carp;
use autodie;

our %fields = (
    logfile   => undef,
    log_index => 0,
);

with 'Lab::Connection::Log';

1;

