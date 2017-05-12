#! /usr/bin/perl

use strict;
use warnings;
use Test::More;
use Log::Any '$log';
use Log::Any::Adapter;

open OLD_STDERR, '>&', \*STDERR or die "Can't dup stderr";
close STDERR;
open STDERR, '>', \my $buf or die "Can't redirect stderr";

my $src_file= __FILE__;
my $src_line= __LINE__ + 1;
Log::Any::Adapter->set('Daemontools', -init => { typo => 5 });
$log->is_debug; # force any lazy-loading

close STDERR;
open STDERR, '>&', \*OLD_STDERR or die "Can't restore stderr";

like( $buf, qr/Invalid arguments: typo at \Q$src_file\E line $src_line/, 'carp error on correct file/line' );

done_testing;
