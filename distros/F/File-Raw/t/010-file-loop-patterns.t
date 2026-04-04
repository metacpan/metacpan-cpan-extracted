#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Raw;

my $tempdir = tempdir(CLEANUP => 1);

# Test file functions with various loop variable patterns

subtest 'for with $path' => sub {
    my @files;
    for my $i (1..3) {
        my $path = "$tempdir/test$i.txt";
        File::Raw::spew($path, "content $i");
        push @files, $path;
    }

    my @contents;
    for my $path (@files) {
        push @contents, File::Raw::slurp($path) if File::Raw::exists($path);
    }
    is(scalar(@contents), 3, 'file ops with $path');
};

subtest 'map with $_ for paths' => sub {
    my @paths = map { "$tempdir/map$_.txt" } (1..3);
    for (@paths) {
        File::Raw::spew($_, "data");
    }
    my @exists = grep { File::Raw::exists($_) } @paths;
    is(scalar(@exists), 3, 'File::Raw::exists with $_ in grep');
};

subtest 'for with $file' => sub {
    my @names = ('alpha', 'beta', 'gamma');
    for my $file (@names) {
        my $path = "$tempdir/$file.txt";
        File::Raw::spew($path, $file);
    }

    my @result;
    for my $file (@names) {
        my $path = "$tempdir/$file.txt";
        push @result, File::Raw::slurp($path);
    }
    is_deeply(\@result, ['alpha', 'beta', 'gamma'], 'file ops with $file');
};

subtest 'for with $name' => sub {
    my @names = qw(one two three);
    for my $name (@names) {
        File::Raw::spew("$tempdir/$name.dat", "data:$name");
    }

    my @data;
    for my $name (@names) {
        push @data, File::Raw::slurp("$tempdir/$name.dat");
    }
    is_deeply(\@data, ['data:one', 'data:two', 'data:three'], 'with $name');
};

subtest 'for with $i numeric index' => sub {
    for my $i (0..4) {
        File::Raw::spew("$tempdir/idx$i.txt", $i * 10);
    }

    my $sum = 0;
    for my $i (0..4) {
        $sum += File::Raw::slurp("$tempdir/idx$i.txt");
    }
    is($sum, 100, 'with $i numeric');
};

subtest 'nested $dir/$file' => sub {
    for my $dir ('dir1', 'dir2') {
        my $dirpath = "$tempdir/$dir";
        mkdir $dirpath;
        for my $file ('a', 'b') {
            File::Raw::spew("$dirpath/$file.txt", "$dir-$file");
        }
    }

    my @contents;
    for my $dir ('dir1', 'dir2') {
        for my $file ('a', 'b') {
            push @contents, File::Raw::slurp("$tempdir/$dir/$file.txt");
        }
    }
    is_deeply(\@contents, ['dir1-a', 'dir1-b', 'dir2-a', 'dir2-b'], 'nested');
};

subtest 'grep with $_ on paths' => sub {
    my @paths = map { "$tempdir/grep$_.txt" } (1..5);
    for my $i (0..$#paths) {
        File::Raw::spew($paths[$i], $i % 2 == 0 ? 'even' : 'odd');
    }

    my @even_files = grep {
        File::Raw::exists($_) && File::Raw::slurp($_) eq 'even'
    } @paths;
    is(scalar(@even_files), 3, 'grep on file contents');
};

subtest 'for with $entry hashref' => sub {
    my @entries = (
        { name => 'e1', content => 'first' },
        { name => 'e2', content => 'second' },
        { name => 'e3', content => 'third' },
    );

    for my $entry (@entries) {
        File::Raw::spew("$tempdir/$entry->{name}.txt", $entry->{content});
    }

    my @read;
    for my $entry (@entries) {
        push @read, File::Raw::slurp("$tempdir/$entry->{name}.txt");
    }
    is_deeply(\@read, ['first', 'second', 'third'], 'with $entry hashref');
};

subtest 'while with $_' => sub {
    my @names = qw(w1 w2 w3);
    my $i = 0;
    while ($i < @names) {
        local $_ = $names[$i];
        File::Raw::spew("$tempdir/$_.txt", "while:$_");
        $i++;
    }

    my @result;
    for (@names) {
        push @result, File::Raw::slurp("$tempdir/$_.txt");
    }
    is_deeply(\@result, ['while:w1', 'while:w2', 'while:w3'], 'while with $_');
};

subtest 'for with $line content' => sub {
    my @lines = ('line 1', 'line 2', 'line 3');
    my $path = "$tempdir/multiline.txt";
    File::Raw::spew($path, join("\n", @lines));

    my $content = File::Raw::slurp($path);
    my @read_lines = split /\n/, $content;

    my @processed;
    for my $line (@read_lines) {
        push @processed, uc($line);
    }
    is_deeply(\@processed, ['LINE 1', 'LINE 2', 'LINE 3'], 'with $line');
};

done_testing();
