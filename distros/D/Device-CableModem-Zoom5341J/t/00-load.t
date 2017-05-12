#!/usr/bin/env perl5

use Test::More tests => 1;
BEGIN { use_ok('Device::CableModem::Zoom5341J') };

diag( "Testing Device::CableModem::Zoom5341J "
    . "$Device::CableModem::Zoom5341J::VERSION, Perl $], $^X" );
