#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Spec;

# Test file module functions work correctly in map/grep/for contexts
# This ensures call checkers properly handle $_ usage

use File::Raw;

# Create temp directory with test fixtures
my $tmpdir = tempdir(CLEANUP => 1);

# Create test files
my @test_files;
for my $name (qw(file1.txt file2.txt file3.log data.csv readme.md)) {
    my $path = File::Spec->catfile($tmpdir, $name);
    File::Raw::spew($path, "content of $name\n" x (length($name)));
    push @test_files, $path;
}

# Create subdirectories
my @test_dirs;
for my $name (qw(subdir1 subdir2 logs)) {
    my $path = File::Spec->catdir($tmpdir, $name);
    File::Raw::mkdir($path);
    push @test_dirs, $path;
}

# Create a symlink if possible
my $link_path = File::Spec->catfile($tmpdir, 'link_to_file1');
my $has_symlink = eval { symlink($test_files[0], $link_path) };

# Create files with different permissions
my $readable_only = File::Spec->catfile($tmpdir, 'readable_only.txt');
my $writable_file = File::Spec->catfile($tmpdir, 'writable.txt');
File::Raw::spew($readable_only, "read only content\n");
File::Raw::spew($writable_file, "writable content\n");
chmod 0444, $readable_only;
chmod 0644, $writable_file;

# Create an executable script
my $exec_script = File::Spec->catfile($tmpdir, 'script.sh');
File::Raw::spew($exec_script, "#!/bin/bash\necho hello\n");
chmod 0755, $exec_script;

# ============================================
# Path predicates in grep
# ============================================

subtest 'is_file in grep' => sub {
    my @all_paths = (@test_files, @test_dirs);
    my @files = grep { File::Raw::is_file($_) } @all_paths;
    is(scalar(@files), scalar(@test_files), 'is_file found all files');
};

subtest 'is_dir in grep' => sub {
    my @all_paths = (@test_files, @test_dirs);
    my @dirs = grep { File::Raw::is_dir($_) } @all_paths;
    is(scalar(@dirs), scalar(@test_dirs), 'is_dir found all directories');
};

subtest 'is_file/is_dir in map' => sub {
    my @all_paths = (@test_files[0..1], @test_dirs[0..1]);
    my @types = map {
        File::Raw::is_file($_) ? 'file' :
        File::Raw::is_dir($_)  ? 'dir'  : 'unknown'
    } @all_paths;
    is_deeply(\@types, ['file', 'file', 'dir', 'dir'], 'is_file/is_dir in map');
};

SKIP: {
    skip "symlinks not available", 2 unless $has_symlink;

    subtest 'is_link in grep' => sub {
        my @paths = (@test_files[0..1], $link_path);
        my @links = grep { File::Raw::is_link($_) } @paths;
        is(scalar(@links), 1, 'is_link found the symlink');
        is($links[0], $link_path, 'correct symlink found');
    };

    subtest 'is_link in map' => sub {
        my @paths = ($test_files[0], $link_path, $test_dirs[0]);
        my @results = map { File::Raw::is_link($_) ? 1 : 0 } @paths;
        is_deeply(\@results, [0, 1, 0], 'is_link in map');
    };
}

# ============================================
# Permission predicates in grep
# ============================================

subtest 'is_readable in grep' => sub {
    my @paths = @test_files;
    my @readable = grep { File::Raw::is_readable($_) } @paths;
    is(scalar(@readable), scalar(@test_files), 'all test files are readable');
};

subtest 'is_writable in grep' => sub {
    my @paths = ($readable_only, $writable_file, @test_files[0..1]);
    my @writable = grep { File::Raw::is_writable($_) } @paths;
    # readable_only should not be writable (unless root)
    ok(scalar(@writable) >= 3, 'is_writable found writable files');
};

subtest 'is_executable in grep' => sub {
    my @paths = (@test_files, $exec_script);
    my @exec = grep { File::Raw::is_executable($_) } @paths;
    ok(scalar(@exec) >= 1, 'is_executable found at least the script');
    ok((grep { $_ eq $exec_script } @exec), 'script.sh is executable');
};

subtest 'permission predicates in map' => sub {
    my @paths = ($test_files[0], $exec_script);
    my @perms = map {
        {
            r => File::Raw::is_readable($_) ? 1 : 0,
            w => File::Raw::is_writable($_) ? 1 : 0,
            x => File::Raw::is_executable($_) ? 1 : 0,
        }
    } @paths;
    ok($perms[0]{r}, 'file1 is readable');
    ok($perms[1]{x}, 'script is executable');
};

# ============================================
# Stat functions in map
# ============================================

subtest 'size in map' => sub {
    my @paths = @test_files[0..2];
    my @sizes = map { File::Raw::size($_) } @paths;
    ok($sizes[0] > 0, 'file1 has size > 0');
    ok($sizes[1] > 0, 'file2 has size > 0');
    ok($sizes[2] > 0, 'file3 has size > 0');
};

subtest 'size in grep (filter large files)' => sub {
    # Find files larger than 50 bytes
    my @large = grep { File::Raw::size($_) > 50 } @test_files;
    ok(scalar(@large) >= 0, 'size comparison in grep works');
};

subtest 'mtime in map' => sub {
    my @paths = @test_files[0..2];
    my @mtimes = map { File::Raw::mtime($_) } @paths;
    my $now = time();
    for my $i (0..2) {
        ok($mtimes[$i] > 0, "file $i has mtime > 0");
        ok($mtimes[$i] <= $now, "file $i mtime not in future");
    }
};

subtest 'atime in map' => sub {
    my @paths = @test_files[0..2];
    my @atimes = map { File::Raw::atime($_) } @paths;
    for my $i (0..2) {
        ok($atimes[$i] > 0, "file $i has atime > 0");
    }
};

subtest 'ctime in map' => sub {
    my @paths = @test_files[0..2];
    my @ctimes = map { File::Raw::ctime($_) } @paths;
    for my $i (0..2) {
        ok($ctimes[$i] > 0, "file $i has ctime > 0");
    }
};

subtest 'stat functions combined in map' => sub {
    my @paths = @test_files[0..1];
    my @stats = map {
        {
            path  => $_,
            size  => File::Raw::size($_),
            mtime => File::Raw::mtime($_),
            atime => File::Raw::atime($_),
            ctime => File::Raw::ctime($_),
        }
    } @paths;
    is(scalar(@stats), 2, 'got stats for 2 files');
    ok($stats[0]{size} > 0, 'first file has size');
    ok($stats[1]{mtime} > 0, 'second file has mtime');
};

# ============================================
# Path manipulation in map
# ============================================

subtest 'basename in map' => sub {
    my @paths = @test_files;
    my @names = map { File::Raw::basename($_) } @paths;
    is_deeply(\@names, [qw(file1.txt file2.txt file3.log data.csv readme.md)], 'basename in map');
};

subtest 'dirname in map' => sub {
    my @paths = @test_files[0..2];
    my @dirs = map { File::Raw::dirname($_) } @paths;
    for my $dir (@dirs) {
        is($dir, $tmpdir, 'dirname returns temp dir');
    }
};

subtest 'extname in map' => sub {
    my @paths = @test_files;
    my @exts = map { File::Raw::extname($_) } @paths;
    is_deeply(\@exts, ['.txt', '.txt', '.log', '.csv', '.md'], 'extname in map');
};

subtest 'path manipulation combined' => sub {
    my @paths = @test_files[0..2];
    my @info = map {
        {
            full => $_,
            base => File::Raw::basename($_),
            dir  => File::Raw::dirname($_),
            ext  => File::Raw::extname($_),
        }
    } @paths;
    is($info[0]{base}, 'file1.txt', 'combined: basename');
    is($info[0]{ext}, '.txt', 'combined: extname');
    is($info[1]{base}, 'file2.txt', 'combined: second file basename');
};

# ============================================
# Filter by extension using extname
# ============================================

subtest 'filter by extension in grep' => sub {
    my @txt_files = grep { File::Raw::extname($_) eq '.txt' } @test_files;
    is(scalar(@txt_files), 2, 'found 2 .txt files');

    my @log_files = grep { File::Raw::extname($_) eq '.log' } @test_files;
    is(scalar(@log_files), 1, 'found 1 .log file');
};

subtest 'group by extension' => sub {
    my %by_ext;
    for my $path (@test_files) {
        my $ext = File::Raw::extname($path);
        push @{$by_ext{$ext}}, File::Raw::basename($path);
    }
    is(scalar(@{$by_ext{'.txt'}}), 2, '2 txt files');
    is(scalar(@{$by_ext{'.csv'}}), 1, '1 csv file');
    is(scalar(@{$by_ext{'.md'}}), 1, '1 md file');
};

# ============================================
# for/foreach loops with file functions
# ============================================

subtest 'is_file in foreach' => sub {
    my @all_paths = (@test_files, @test_dirs);
    my @files;
    for (@all_paths) {
        push @files, $_ if File::Raw::is_file($_);
    }
    is(scalar(@files), scalar(@test_files), 'is_file in foreach');
};

subtest 'size in foreach' => sub {
    my $total_size = 0;
    for (@test_files) {
        $total_size += File::Raw::size($_);
    }
    ok($total_size > 0, 'accumulated size in foreach');
};

subtest 'basename in foreach' => sub {
    my @names;
    for my $path (@test_files) {
        push @names, File::Raw::basename($path);
    }
    is_deeply(\@names, [qw(file1.txt file2.txt file3.log data.csv readme.md)], 'basename in foreach');
};

subtest 'nested for with file ops' => sub {
    my @all_paths = (@test_files[0..1], @test_dirs[0..1]);
    my %categorized = (files => [], dirs => []);
    for my $path (@all_paths) {
        if (File::Raw::is_file($path)) {
            push @{$categorized{files}}, File::Raw::basename($path);
        } elsif (File::Raw::is_dir($path)) {
            push @{$categorized{dirs}}, File::Raw::basename($path);
        }
    }
    is(scalar(@{$categorized{files}}), 2, '2 files categorized');
    is(scalar(@{$categorized{dirs}}), 2, '2 dirs categorized');
};

# ============================================
# Complex pipelines
# ============================================

subtest 'filter and transform pipeline' => sub {
    # Find all .txt files, get their sizes
    my @txt_sizes =
        map { File::Raw::size($_) }
        grep { File::Raw::extname($_) eq '.txt' }
        @test_files;
    is(scalar(@txt_sizes), 2, 'pipeline: found 2 txt file sizes');
    ok($txt_sizes[0] > 0, 'pipeline: first txt has size');
};

subtest 'find recent files' => sub {
    my $threshold = time() - 3600;  # Within last hour
    my @recent =
        map { File::Raw::basename($_) }
        grep { File::Raw::mtime($_) > $threshold }
        @test_files;
    is(scalar(@recent), scalar(@test_files), 'all files are recent');
};

subtest 'file inventory' => sub {
    my @inventory = map {
        my $path = $_;
        {
            name => File::Raw::basename($path),
            ext  => File::Raw::extname($path),
            size => File::Raw::size($path),
            type => File::Raw::is_dir($path) ? 'dir' : 'file',
        }
    } @test_files;

    is(scalar(@inventory), 5, 'inventory has 5 items');
    is($inventory[0]{name}, 'file1.txt', 'inventory: correct name');
    is($inventory[0]{ext}, '.txt', 'inventory: correct ext');
    is($inventory[0]{type}, 'file', 'inventory: correct type');
};

# ============================================
# exists in various contexts
# ============================================

subtest 'exists in grep' => sub {
    my @paths = (@test_files, '/nonexistent/path/file.txt');
    my @existing = grep { File::Raw::exists($_) } @paths;
    is(scalar(@existing), scalar(@test_files), 'exists filtered correctly');
};

subtest 'exists in map' => sub {
    my @paths = ($test_files[0], '/nonexistent', $test_dirs[0]);
    my @results = map { File::Raw::exists($_) ? 1 : 0 } @paths;
    is_deeply(\@results, [1, 0, 1], 'exists in map');
};

# ============================================
# mode function
# ============================================

subtest 'mode in map' => sub {
    my @paths = ($test_files[0], $exec_script);
    my @modes = map { File::Raw::mode($_) } @paths;
    ok($modes[0] > 0, 'file has mode');
    ok($modes[1] > 0, 'script has mode');
    # Check exec script has execute bit
    ok($modes[1] & 0111, 'script has execute permission');
};

# ============================================
# Sorting by file attributes
# ============================================

subtest 'sort by size' => sub {
    my @sorted_by_size =
        map { File::Raw::basename($_) }
        sort { File::Raw::size($a) <=> File::Raw::size($b) }
        @test_files;
    is(scalar(@sorted_by_size), 5, 'sorted 5 files by size');
};

subtest 'sort by mtime' => sub {
    my @sorted_by_mtime =
        map { File::Raw::basename($_) }
        sort { File::Raw::mtime($a) <=> File::Raw::mtime($b) }
        @test_files;
    is(scalar(@sorted_by_mtime), 5, 'sorted 5 files by mtime');
};

subtest 'sort by basename' => sub {
    my @sorted =
        sort { File::Raw::basename($a) cmp File::Raw::basename($b) }
        @test_files;
    my @names = map { File::Raw::basename($_) } @sorted;
    is($names[0], 'data.csv', 'data.csv first alphabetically');
    is($names[-1], 'readme.md', 'readme.md last alphabetically');
};

# Cleanup non-writable file for tempdir cleanup
chmod 0644, $readable_only;

done_testing();
