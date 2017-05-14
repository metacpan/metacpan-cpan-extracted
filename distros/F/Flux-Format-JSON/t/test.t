#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 3;
use Test::NoWarnings;

use lib 'lib';
use utf8;

use File::Path qw(remove_tree);
use autodie qw(mkdir);

use Flux::File;
use Flux::Storage::Memory;
use Flux::Format::JSON;

my $storage = Flux::Storage::Memory->new();

my $format = Flux::Format::JSON->new;

subtest 'in-memory' => sub {
    my $formatted_storage = $format->wrap($storage);
    $formatted_storage->write({ abc => "def" });
    $formatted_storage->write("ghi");
    $formatted_storage->commit;

    is_deeply $storage->data, [
        qq[{"abc":"def"}\n],
        qq["ghi"\n],
    ];

    my $in = $formatted_storage->in('c1');
    is_deeply(scalar($in->read), { abc => 'def' }, 'data deserialized correctly');
    is_deeply(scalar($in->read), 'ghi', 'simple strings can be stored too');
    $in->commit;
    undef $in;

    $in = $formatted_storage->in('c1');
    is($in->read, undef, 'commit worked, nothing to read');
};

subtest 'wide characters' => sub {
    remove_tree 'tfiles' if -d 'tfiles';
    mkdir 'tfiles';
    my $file_storage = $format->wrap(Flux::File->new('tfiles/file'));
    $file_storage->write("абв\n");
    $file_storage->commit;
    my $file_in = $file_storage->in('tfiles/pos');
    is $file_in->read, "абв\n";

    remove_tree 'tfiles';
};
