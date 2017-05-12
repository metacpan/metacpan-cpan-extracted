#!/usr/bin/perl
use strict;
use warnings;

use HTML::PodCodeReformat;

use Text::Diff;
use File::Spec::Functions;

use Test::More tests => 4;

my $f;
my $fixed_html;
my $filename1;
my $diff;
my $patchfile1;
my $patchtext;
my $htmltext;

$f = HTML::PodCodeReformat->new;

$filename1 = catfile qw( t data DBD-SQLite-Cookbook.pod.html );
#$filename = 't/data/DataFlow.pm.html';
$patchfile1 = catfile qw( t data DBD-SQLite-Cookbook.pod.html.patch );
#$patchfile = 't/data/DataFlow.pm.html.patch';

$fixed_html = $f->reformat_pre( $filename1 );

$diff = diff( $filename1, \$fixed_html );

{
    open my $fh, '<', $patchfile1
        or die "Can't open file $patchfile1: ", $!;
    $patchtext = do { local $/; <$fh> };
}

is( $diff, $patchtext, 'CPAN Search file' );

##### squash_blank_lines

$f->squash_blank_lines(1);
$fixed_html = $f->reformat_pre( $filename1 );

$diff = diff( $filename1, \$fixed_html );

is( $diff, $patchtext, 'CPAN Search file squashed' );

##### filehandle

open my $fh_param, '<', $filename1
    or die "Can't open file $filename1: ", $!;

$fixed_html = $f->reformat_pre( $fh_param );

$diff = diff( $filename1, \$fixed_html );

is( $diff, $patchtext, 'CPAN Search filehandle' );

##### string

{
    open my $fh, '<', $filename1
        or die "Can't open file $filename1: ", $!;
    $htmltext = do { local $/; <$fh> };
}

$fixed_html = $f->reformat_pre( \$htmltext );

$diff = diff( $filename1, \$fixed_html );

is( $diff, $patchtext, 'CPAN Search string' );
