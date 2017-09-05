#!/usr/bin/perl

# Test escaped comment markers, JavaScript and Perl

use 5.008;
use strict;
use warnings;

use File::Basename 'dirname';
use File::Spec;

use Test::More;

use JSON::WithComments;

plan tests => 6;

my $BASEDIR = dirname __FILE__;

my ($json, $data, $res);

$json = JSON::WithComments->new;

$data = read_file('escape-js.json');
$res = eval { $json->decode($data); };
if ($res) {
    # No need to check the content of $res, the JSON module tests itself pretty
    # well.
    pass('Escaped JavaScript comments');
} else {
    fail("Escaped JavaScript comments failed: $@");
}
SKIP: {
    if (! $res) {
        skip 'Parsing failed', 3;
    }

    is($res->{key1}, '// scalar value', 'Correct escaped line comment');
    is($res->{key2}, '/* start', 'Escaped block-comment start');
    is($res->{key3}, 'end */', 'Escaped block-comment end');
}

$json->comment_style('perl');
$data = read_file('escape-pl.json');
$res = eval { $json->decode($data); };
if ($res) {
    pass('Escaped Perl comments');
} else {
    fail("Escaped Perl comments failed: $@");
}
SKIP: {
    if (! $res) {
        skip 'Parsing failed', 1;
    }

    # This is a misnomer, as we don't actually escape Perl comments in strings
    # after all...
    is($res->{key1}, '# scalar value', 'Correct "escaped" Perl string');
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
