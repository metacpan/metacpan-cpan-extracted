#! /usr/bin/perl -w
use lib '../lib';
use strict;

my ( $tests, %test_cases );

BEGIN {
    $tests      = 9;
    %test_cases = (
        'test.pl'  => ['Perl'],
        'test.pm'  => ['Perl'],
        'test.cgi' => ['Perl'],
    );
    eval {
        require Template;
        %test_cases = (
            %test_cases,
            'test.tt'    => ['TT2'],
            'test.tt2'   => ['TT2'],
            'test.html'  => ['TT2'],
            'test.tt.*'  => ['TT2'],
            'test.tt2.*' => ['TT2'],
        );
        $tests += 10;
    };
    eval {
        require YAML::Loader;
        %test_cases = (
            %test_cases,
            'test.yaml' => [ 'YAML', 'FormFu' ],
            'test.yml'  => [ 'YAML', 'FormFu' ],
            'test.conf' => [ 'YAML', 'FormFu' ],
        );
        $tests += 9;
    };
}

use Test::More tests => $tests;

use_ok('Locale::Maketext::Extract');
my $Ext = Locale::Maketext::Extract->new;

isa_ok( $Ext => 'Locale::Maketext::Extract' );

while ( my ( $filename, $expected ) = each %test_cases ) {
    my @plugins = $Ext->_plugins_specifically_for_file($filename);

    cmp_ok(
        scalar(@plugins), '==',
        scalar( @{$expected} ),
        "Number of plugins suitable for use with $filename match."
    );

    foreach my $name ( @{$expected} ) {
        my $present
            = grep { "Locale::Maketext::Extract::Plugin::$name" eq ref $_ }
            @plugins;
        ok( $present, "Got all expected plugins for $filename." );
    }
}

my @plugins = $Ext->_plugins_specifically_for_file('test.idk');
cmp_ok( scalar(@plugins), '==', 0,
    'No specific plugins for unknown file type.' );
