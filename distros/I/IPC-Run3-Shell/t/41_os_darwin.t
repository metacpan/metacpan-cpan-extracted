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

# ### PLEASE SEE NOTE IN 40_os_nix.t ###

use Test::More ($^O eq 'darwin') ? (tests=>3)
	: (skip_all=>"these tests run on darwin, this is $^O");

use IPC::Run3::Shell;
use warnings FATAL=>'IPC::Run3::Shell';

my $s = IPC::Run3::Shell->new;

my $d = $s->defaults('read','NSGlobalDomain');
is $?, 0, 'defaults ran ok';
like $d, qr/\bAppleLocale\b/, 'found AppleLocale key';

my @ps = grep { /\b(?:Dock|KernelEventAgent|SystemStarter)\b/ } $s->ps(-ax);
is $?, 0, 'ps ran ok';
note "selected system processes: @ps";

