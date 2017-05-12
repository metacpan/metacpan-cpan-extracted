#!/usr/bin/perl

use lib 'lib', '../lib';

use Exception::Base 'Exception::Died';

eval { open my $file, "x", "/badmodeexample" };
warn "\$@ = $@";
Exception::Died->throw( $@, message=>"cannot open" ) if $@;
