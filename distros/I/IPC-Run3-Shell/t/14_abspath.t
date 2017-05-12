#!/usr/bin/env perl
use warnings;
use strict;

# Tests for the Perl module IPC::Run3::Shell
# 
# Copyright (c) 2014 Hauke Daempfling (haukex@zero-g.net).
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

use Test::More tests => 3;

# Note: The CPAN Testers wiki recommends to use $Config{perlpath} instead of $^X.
use Config;

use File::Spec::Functions 'file_name_is_absolute';
# if the following check fails, the tests following it are inconclusive
ok file_name_is_absolute($Config{perlpath}), "perl path is absolute ($Config{perlpath})";

use IPC::Run3::Shell ':run', [ pl => $Config{perlpath}, '-e' ];
use warnings FATAL=>'IPC::Run3::Shell';

is pl("print 'baz'"), 'baz', 'alias with full pathname';

is run($Config{perlpath},'-e','print "quz"'), 'quz', 'run with full pathname';

