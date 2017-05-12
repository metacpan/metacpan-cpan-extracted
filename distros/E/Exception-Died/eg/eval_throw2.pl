#!/usr/bin/perl

use lib 'lib', '../lib';

use Exception::Base;
use Exception::Died '%SIG';

eval { open my $file, "x", "/badmodeexample" };
warn "\$@ = $@";
Exception::Died->throw( $@, message=>"cannot open" ) if $@;
