#!/usr/local/bin/perl -w
# $Id: trace_dump.t,v 1.4 2005/11/24 10:53:12 tonyh Exp $

use strict;
use Test::More tests => 9;

# Find local libs unless running under Test::Harness
BEGIN { unshift @INC, -d 't' ? 'lib' : '../lib' unless grep /\bblib\b/, @INC }
require_ok('Log::Trace');

my $output;
my $trace = sub {
    $output = shift;
    0 && do {
        my $expected = $output;
        $expected =~ s/([@"\$\\])/\\$1/g;
        $expected =~ s/\t/\\t/g;
        $expected =~ s/\n/\\n/g;
        # print $expected, $/;
    }
};

SKIP: {
    eval { require Data::Dumper };
    skip "Data::Dumper not installed", 4, if $@;

    import Log::Trace custom => $trace;

    DUMP([1,2,3]);
    my $expected = "\$VAR1 = [\n  1,\n  2,\n  3\n];\n";
    is ($output, $expected, 'simple DUMP with DD');

    $output = '';
    DUMP('prepended message', { somewhat => [qw(more complicated)] }, 'foo');
    $expected = "prepended message: \$VAR1 = {\n  somewhat => [\n    'more',\n    'complicated'\n  ]\n};\n\$VAR2 = 'foo';\n";
    is($output, $expected, 'dump with a comment');

    $output = '';
    my $dumped = DUMP("this isn't traced", [qw(it is returned instead)]);
    $expected = "this isn't traced: \$VAR1 = [\n  'it',\n  'is',\n  'returned',\n  'instead'\n];\n";
    is($output, '', 'dump in non-void context does not TRACE');
    is ($dumped, $expected, 'in non-void context it returns the DUMP');
}

SKIP: {
    eval { require Data::Serializer };
    skip "Data::Serializer not installed", 4, if $@;
    eval { require Data::Dumper     };
    skip "Data::Dumper not installed", 4, if $@;

    import Log::Trace custom => $trace, { Dumper => 'Data::Dumper' };

    DUMP([1,2,3]);
    my $expected = "[1,2,3]\n";
    is ($output, $expected, 'simple DUMP with DS');

    $output = '';
    DUMP('prepended message', { somewhat => [qw(more complicated)] }, { 'foo' => 'bar' });
    $expected = "prepended message: {'somewhat' => ['more','complicated']}\n{'foo' => 'bar'}\n";
    is($output, $expected, 'dump with a comment');

    $output = '';
    my $dumped = DUMP("this isn't traced", [qw(it is returned instead)]);
    $expected = "this isn't traced: ['it','is','returned','instead']\n";
    is($output, '', 'dump in non-void context does not TRACE');
    is ($dumped, $expected, 'in non-void context it returns the DUMP');
}

sub TRACE {}
sub DUMP  {}
