#!/usr/bin/perl -w

use Test::More;
use strict;

BEGIN
   {
   plan tests => 6;
   chdir 't' if -d 't';
   };

my $gen = '../';
$gen = 'perl ..\\' if $^O =~ /MSWin32/i;
$gen .= 'gen_graph';

#############################################################################
# --version
my $rc = `$gen --version`;

like ($rc, qr/v\d\.\d\d/, 'version found');
unlike ($rc, qr/Usage:/, 'no help in --version');

#############################################################################
# --help

$rc = `$gen --help 2>&1`;

like ($rc, qr/v\d\.\d\d/, 'version found');
like ($rc, qr/Usage:/, 'help found');
like ($rc, qr/Options:/, 'help found');

#############################################################################
# --debug

$rc = `$gen --debug --version 2>&1`;

like ($rc, qr/v\d\.\d\d/, 'version found');

