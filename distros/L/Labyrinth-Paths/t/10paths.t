#!/usr/bin/perl -w
use strict;

use Data::Dumper;
use Labyrinth::Paths;
use Labyrinth::Variables;
use Test::More  tests => 18;

my $testfile1 = './t/data/pathfile1.json';
my $testfile2 = './t/data/pathfile2.json';

my $data1 = [
    {
        'settings' => { 'test' => 1 },
        'variables' => [ 'pageid' ],
        'path' => '/page/(\\d+)',
        'cgiparams' => { 'act' => 'home-page' }
    }
];

my $data2 = [
    {
        'settings' => { 'test' => 1 },
        'variables' => [ 'pagename' ],
        'path' => '/page/(\\w+).html',
        'cgiparams' => { 'act' => 'home-page' }
    }
];

{
    my $paths = Labyrinth::Paths->new();
    isa_ok($paths, 'Labyrinth::Paths');
    is($paths->{pathfile},'./pathfile.json','default file');

    $paths->load;
    is($paths->{data},undef,'no data file found');
}

{
    my $paths = Labyrinth::Paths->new($testfile1);
    isa_ok($paths, 'Labyrinth::Paths');
    is($paths->{pathfile},$testfile1,'first data file');

    $paths->load;
    is_deeply($paths->{data},$data1,'first data file loaded');
}

{
    $settings{pathfile} = $testfile2;
    my $paths = Labyrinth::Paths->new();
    isa_ok($paths, 'Labyrinth::Paths');
    is($paths->{pathfile},$testfile2,'second data file');

    $paths->load;
    is_deeply($paths->{data},$data2,'second data file loaded');

    $paths->load($testfile1);
    is_deeply($paths->{data},$data1,'first data file loaded');

    $paths->parse;

    $ENV{SCRIPT_URL} = '';
    $paths->parse;
    is($cgiparams{act},undef);

    $ENV{SCRIPT_URL} = '';
    $ENV{SCRIPT_NAME} = '';
    $paths->parse;
    is($cgiparams{act},undef);

    $ENV{SCRIPT_URL} = '/page/123';
    $paths->parse;
    is($cgiparams{act},'home-page');
    is($cgiparams{pageid},123);

    $ENV{SCRIPT_URL} = '';
    $ENV{SCRIPT_NAME} = '/page/456';
    $paths->parse;
    is($cgiparams{act},'home-page');
    is($cgiparams{pageid},456);

    %cgiparams = ();
    $ENV{SCRIPT_URL} = '/page/this.html';
    $paths->parse;
    is($cgiparams{act},undef);
    is($cgiparams{pageid},undef);

}

