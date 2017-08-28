#!/usr/bin/perl

# Basic tests, handling comments in both JS and Perl

use 5.008;
use strict;
use warnings;

use File::Basename 'dirname';
use File::Spec;

use Test::More;

use JSON::WithComments;

plan tests => 5;

my $BASEDIR = dirname __FILE__;

my ($json, $data, $res);

$json = JSON::WithComments->new;
isa_ok($json, 'JSON::WithComments', 'Object');
is($json->get_comment_style, 'javascript', 'Default comment style');

$data = read_file('basic-js.json');
$res = eval { $json->decode($data); };
if ($res) {
    # No need to check the content of $res, the JSON module tests itself pretty
    # well.
    pass('Basic JavaScript comments');
} else {
    fail("Basic JavaScript comments failed: $@");
}

$json->comment_style('perl');
is($json->get_comment_style, 'perl', 'Changed comment style');
$data = read_file('basic-pl.json');
$res = eval { $json->decode($data); };
if ($res) {
    pass('Basic Perl comments');
} else {
    fail("Basic Perl comments failed: $@");
}

exit;

sub read_file {
    my $file = shift;
    my $content;

    $file = File::Spec->catfile($BASEDIR, $file);
    if (open my $fh, '<', $file) {
        undef $/;
        $content = <$fh>;
        close $fh or die "Error closing $file: $!\n";
    } else {
        die "Error opening $file for reading: $!\n";
    }

    return $content;
}
