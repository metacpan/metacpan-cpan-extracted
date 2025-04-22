#!/usr/bin/perl -w 

use strict;
use warnings;
use v5.10;
use lib 'lib', '../lib'; # able to run prove in project dir and .t locally

use Test::More;
use File::Temp;
use File::Spec;

use constant {
    TEST_STRING     => 'Hello World!',
    TEST_CONTENTISE => 'dc4dd92e-da6e-584b-ad70-7a3193b72ebb',
};

use_ok('File::FStore');

my $tempdir = File::Temp->newdir;
my $path = File::Spec->catdir($tempdir->dirname, 'store');

my $f = File::Spec->catfile($tempdir->dirname, 'test-file');

{
    open(my $fh, '>', $f);
    $fh->print(TEST_STRING);
    $fh->close;
}

# Only create
my $store = eval { File::FStore->create(path => $path) };
isa_ok($store, 'File::FStore');

my $adder = $store->new_adder;
isa_ok($adder, 'File::FStore::Adder');

$adder->move_in($f);

ok(!-e $f, 'File was moved');

$adder->insert;

undef($adder);

$store->close;


# Open:
$store = eval { File::FStore->new(path => $path) };
isa_ok($store, 'File::FStore');

my $file = $store->query(ise => TEST_CONTENTISE);

isa_ok($file, 'File::FStore::File');

is(scalar(eval {$file->get(properties => 'size')}), length(TEST_STRING), 'Size matches');

isa_ok(scalar(eval {$file->as('Data::Identifier')}), 'Data::Identifier');

{
    my $fh = $file->open;
    my $data;

    ok(defined($fh), 'Can open file');

    $data = do {
        local $/ = undef;
        readline($fh);
    };

    $fh->close;

    is($data, TEST_STRING, 'File is not corrupted');
}

ok(defined(eval {$file->update; 1}), 'Update passes');

$store->close;

done_testing();

exit 0;

