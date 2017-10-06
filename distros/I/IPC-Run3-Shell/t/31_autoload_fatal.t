#!/usr/bin/env perl
use warnings;
use strict;

# Tests for the Perl module IPC::Run3::Shell
# 
# Copyright (c) 2017 Hauke Daempfling (haukex@zero-g.net).
# 
# This library is free software; you can redistribute it and/or modify
# it under the same terms as Perl 5 itself.
# 
# For more information see the "Perl Artistic License",
# which should have been distributed with your copy of Perl.
# Try the command "perldoc perlartistic" or see
# http://perldoc.perl.org/perlartistic.html .

use FindBin ();
use lib $FindBin::Bin;
use IPC_Run3_Shell_Testlib;

use Test::More tests => 2;
use Test::Fatal 'exception';

use IPC::Run3::Shell qw/ :AUTOLOAD :FATAL /;

output_is { perl('-e','print "foo bar"'); 1 } 'foo bar', '', "autoloaded perl()";

like exception { perl('-e','exit 1'); 1 },
    qr/exit (status|value) 1\b/, "fail";

done_testing;

