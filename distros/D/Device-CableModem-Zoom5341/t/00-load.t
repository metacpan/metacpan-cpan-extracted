#!/usr/bin/env perl5

use Test::More tests => 1;
BEGIN { use_ok('Device::CableModem::Zoom5341') };

diag( "Testing Device::CableModem::Zoom5341 "
    . "$Device::CableModem::Zoom5341::VERSION, Perl $], $^X" );
