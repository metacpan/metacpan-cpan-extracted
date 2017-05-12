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

use Test::More tests => 5;

use IPC::Run3::Shell {show_cmd=>1}, 'perl';
use warnings FATAL=>'IPC::Run3::Shell';

output_is { perl('-e','print q(foo bar)'); 1 }
	'foo bar', "\$ perl -e \"print q(foo bar)\"\n", 'show_cmd simple';

output_is { perl({show_cmd=>\*STDOUT},'-e','print q(foo bar)'); 1 }
	"\$ perl -e \"print q(foo bar)\"\nfoo bar", '', 'show_cmd redir';

output_is { perl('-e','print "foo bar"'); 1 }
	'foo bar', "\$ perl -e \"print \\\"foo bar\\\"\"\n", 'show_cmd quotes';

output_is { perl('-e','print "foo bar\n"'); 1 }
	"foo bar\n", "\$ perl -e \"print \\\"foo bar\\\\n\\\"\"\n", 'show_cmd newline';

output_is { perl('-e','print "foo bar\n"','--','--quz=/baz/.blah','foo@bar'); 1 }
	"foo bar\n", "\$ perl -e \"print \\\"foo bar\\\\n\\\"\" -- --quz=/baz/.blah \"foo\\\@bar\"\n", 'show_cmd complex';

