#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

# Test file module functions work correctly in map/grep context
# This ensures call checkers properly handle $_ usage

use File::Raw;

my $tempdir = tempdir(CLEANUP => 1);

# Create test files
my @files;
for my $i (1..3) {
    my $path = "$tempdir/test$i.txt";
    File::Raw::spew($path, "content $i line 1\ncontent $i line 2");
    push @files, $path;
}

# ============================================
# File::Raw::slurp in map (1-arg custom op)
# ============================================
subtest 'File::Raw::slurp in map' => sub {
    my @contents = map { File::Raw::slurp($_) } @files;
    is(scalar(@contents), 3, 'slurp returns 3 results in map');
    like($contents[0], qr/content 1/, 'first file content correct');
    like($contents[1], qr/content 2/, 'second file content correct');
    like($contents[2], qr/content 3/, 'third file content correct');
};

# ============================================
# File::Raw::slurp in grep
# ============================================
subtest 'File::Raw::slurp in grep' => sub {
    # Create a file with specific content
    my $special = "$tempdir/special.txt";
    File::Raw::spew($special, "MARKER_FOUND");
    
    my @test_files = (@files, $special);
    my @matching = grep { File::Raw::slurp($_) =~ /MARKER/ } @test_files;
    is(scalar(@matching), 1, 'grep finds 1 matching file');
    is($matching[0], $special, 'correct file matched');
};

# ============================================
# File::Raw::exists in map/grep
# ============================================
subtest 'File::Raw::exists in map/grep' => sub {
    my $nonexistent = "$tempdir/nonexistent.txt";
    my @test_files = (@files, $nonexistent);
    
    my @existing = grep { File::Raw::exists($_) } @test_files;
    is(scalar(@existing), 3, 'grep finds 3 existing files');
    
    my @results = map { File::Raw::exists($_) ? 1 : 0 } @test_files;
    is_deeply(\@results, [1, 1, 1, 0], 'map returns correct existence flags');
};

# ============================================
# File::Raw::lines in map
# ============================================
subtest 'File::Raw::lines in map' => sub {
    # File::Raw::lines returns an arrayref
    my @all_lines = map { File::Raw::lines($_) } @files;
    is(scalar(@all_lines), 3, 'lines returns 3 arrayrefs in map');
    is(scalar(@{$all_lines[0]}), 2, 'first file has 2 lines');
    is(scalar(@{$all_lines[1]}), 2, 'second file has 2 lines');
};

# ============================================
# Nested map with file operations
# ============================================
subtest 'nested map with file' => sub {
    # Use (\@files) to create array of arrayrefs, not [\@files] which nests an extra level
    my @file_groups = (\@files);
    my @results = map {
        my $group = $_;
        [ map { File::Raw::exists($_) ? 1 : 0 } @$group ]
    } @file_groups;
    is_deeply($results[0], [1, 1, 1], 'nested map with File::Raw::exists works');
};

# ============================================
# for/foreach loops with file functions
# ============================================
subtest 'File::Raw::slurp in foreach loop' => sub {
    my @contents;
    for (@files) {
        push @contents, File::Raw::slurp($_);
    }
    is(scalar(@contents), 3, 'slurp in foreach returns 3 results');
    like($contents[0], qr/content 1/, 'first file slurped in foreach');
};

subtest 'File::Raw::exists in for loop' => sub {
    my $nonexistent = "$tempdir/nonexistent.txt";
    my @test_files = (@files, $nonexistent);
    
    my $count = 0;
    for (@test_files) {
        $count++ if File::Raw::exists($_);
    }
    is($count, 3, 'exists counts correctly in for loop with $_');
};

subtest 'nested for with file operations' => sub {
    my @file_groups = (\@files);
    my @results;
    for my $group (@file_groups) {
        my @exists;
        for (@$group) {
            push @exists, File::Raw::exists($_) ? 1 : 0;
        }
        push @results, \@exists;
    }
    is_deeply($results[0], [1, 1, 1], 'nested for with File::Raw::exists works');
};

done_testing();
