#!/usr/bin/env perl
use strict;
use warnings;
use Path::Class;
use File::Temp;

my $dir = shift @ARGV;
$dir ||= File::Temp::tempdir( 'cpan-testers-XXXX', TMPDIR => 1, CLEANUP => 1 );
die "'$dir' is not a directory\n" unless -d $dir;

my $bindir = file($0)->dir;
system( $^X, $bindir->file('generate_config.pl'), $dir );
system( $^X, $bindir->file('cpan-testers-metabase.pl'), '-C', file($dir,'config.json'), '-d' );

