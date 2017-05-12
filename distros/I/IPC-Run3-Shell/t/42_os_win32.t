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

use Test::More ($^O eq 'MSWin32') ? (tests=>2)
	: (skip_all=>"these tests run on MSWin32, this is $^O");

use IPC::Run3::Shell;
use warnings FATAL=>'IPC::Run3::Shell';

my $s = IPC::Run3::Shell->new;

use File::Temp 'tempfile';
my ($fh, $fn) = tempfile(UNLINK=>1);
binmode $fh, ':crlf';
print {$fh} "p1\n","h0\n","j3\n","a2\n";
close $fh;
note "sort tempfile: $fn";

my @o = $s->sort({chomp=>1},'/r','/+2',$fn);
is $?, 0, 'sort ran ok';
is_deeply \@o, ['j3','a2','p1','h0'], 'sort output correct (switches worked)';

