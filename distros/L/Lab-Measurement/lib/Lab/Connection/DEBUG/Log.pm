package Lab::Connection::DEBUG::Log;
use 5.010;
use warnings;
use strict;

use parent 'Lab::Connection::DEBUG';

use Role::Tiny::With;
use Carp;
use autodie;

our $VERSION = '3.543';

our %fields = (
    logfile   => undef,
    log_index => 0,
);

with 'Lab::Connection::Log';

1;

