# -*- perl -*-
# t/002-dircopy.t - tests of dircopy() method
use strict;
use warnings;

use Test::More tests => 115;
use File::Copy::Recursive::Reduced qw(dircopy);

use Capture::Tiny qw(capture_stderr);
use File::Find;
use File::Path qw(mkpath);
use File::Spec;
use File::Temp qw(tempdir);
use lib qw( t/lib );
use MockHomeDir;
use Helper ( qw|
    create_tfile
    create_tfile_and_name_for_new_file_in_same_dir
    create_tsubdir
    touch_a_file_and_test
    touch_directories_and_test
    touch_left_path_and_test
    prepare_left_side_directories
    make_mixed_directory
    make_imperfect_mixed_directory
| );

my ($from, $to, $rv);

{
    note("dircopy(): Argument validation");

    $rv = dircopy();
    ok(! defined $rv, "dircopy() returned undef when not provided correct number of arguments");

    $rv = dircopy('foo');
    ok(! defined $rv, "dircopy() returned undef when not provided correct number of arguments");

    $rv = dircopy('foo', 'bar', 'baz', 'bletch');
    ok(! defined $rv, "dircopy() returned undef when not provided correct number of arguments");

    $rv = dircopy(undef, 'foo');
    ok(! defined $rv, "dircopy() returned undef when first argument was undefined");

    $rv = dircopy('foo', undef);
    ok(! defined $rv, "dircopy() returned undef when second argument was undefined");

    $rv = dircopy('foo', 'foo');
    ok(! defined $rv, "dircopy() returned undef when provided 2 identical arguments");

    SKIP: {
        skip "System does not support hard links", 3
            unless $File::Copy::Recursive::Reduced::Link;
        my $tdir = tempdir( CLEANUP => 1 );
        my ($old, $new) = create_tfile_and_name_for_new_file_in_same_dir($tdir);
        my $rv = link($old, $new) or die "Unable to link: $!";
        ok($rv, "Able to hard link $old and $new");
        my $stderr = capture_stderr { $rv = dircopy($old, $new); };
        ok(! defined $rv,
            "dircopy() returned undef when provided arguments with identical dev and ino");
        SKIP: {
            skip 'identical-dev-ino check not applicable on Windows', 1
                if ($^O eq 'MSWin32') ;
            like($stderr, qr/\Q$old and $new are identical\E/,
                "dircopy(): got expected warning when provided arguments with identical dev and ino");
        }
    }

    {
        note("Either first argument is not a directory or\nsecond argument exists already and is not a directory");
        my ($tdir, $old, $new, $rv);
        $tdir = tempdir( CLEANUP => 1 );
        $old = create_tfile($tdir);
        $new = 'foo';
        $rv = dircopy($old, $new);
        ok(! defined $rv, "dircopy() returned undef when first argument was not a directory");
        cmp_ok($!, '>=', 0, "\$ERRNO set: " . $!);
        undef $!;
        ok(! $!, "\$ERRORNO has been cleared");

        $old = create_tsubdir($tdir);
        $new = create_tfile($tdir, 'new');
        $rv = dircopy($old, $new);
        ok(! defined $rv,
            "dircopy() returned undef when second argument -- not a directory -- already existed");
        cmp_ok($!, '>=', 0, "\$ERRNO set: " . $!);
        undef $!;
    }
}

note("Begin tests with valid arguments");

{
    note("Second argument (directory) does not yet exist");
    my $topdir = tempdir(CLEANUP => 1);
    my ($tdir, $tdir2);
    $tdir = File::Spec->catdir($topdir, 'alpha');
    mkpath($tdir) or die "Unable to mkpath $tdir";
    ok(-d $tdir, "Directory $tdir created");
    my $f1 = create_tfile($tdir, 'foo');
    my $f2 = create_tfile($tdir, 'bar');
    $tdir2 = File::Spec->catdir($topdir, 'beta');
    ok(! -d $tdir2, "Directory $tdir2 does not yet exist");

    my ($from, $to);
    $from = $tdir;
    $to = $tdir2;
    $rv = dircopy($from, $to);
    ok(defined $rv, "dircopy() returned defined value");
    ok(-d $tdir2, "Directory $tdir2 has been created");
}

{
    note("Copying of subdirs containing no files");
    my $topdir = tempdir(CLEANUP => 1);
    my @tdir_names = ('xray', 'yeller');
    my @tdirs = touch_directories_and_test($topdir, \@tdir_names);
    my @subdir_names = ('alpha', 'beta', 'gamma');
    my $ldir = touch_left_path_and_test($tdirs[0], @subdir_names);
    my @expected_subdirs = ();
    my $intermed = $tdirs[1];
    for my $d (@subdir_names) {
        $intermed = File::Spec->catdir($intermed, $d);
        push @expected_subdirs, $intermed;
    }
    for my $d (@expected_subdirs) {
        ok(! -d $d, "Directory $d does not yet exist");
    }

    my ($from, $to);
    $from = $tdirs[0];
    $to = $tdirs[1];
    $rv = dircopy($from, $to);
    ok(defined $rv, "dircopy() returned defined value");
    for my $d (@expected_subdirs) {
        ok(-d $d, "Directory $d has been created");
    }
}

{
    note("Copying of subdirs containing 1 file at bottom level");
    my $topdir = tempdir(CLEANUP => 1);
    my @tdir_names = ('xray', 'yeller');
    my @tdirs = touch_directories_and_test($topdir, \@tdir_names);
    my @subdir_names = ('alpha', 'beta', 'gamma');
    my $ldir = touch_left_path_and_test($tdirs[0], @subdir_names);
    my $fname = 'foo';
    my $f1 = create_tfile($ldir, $fname);
    ok(-f $f1, "File      $f1 created at bottom level");
    my @expected_subdirs = ();
    my $intermed = $tdirs[1];
    for my $d (@subdir_names) {
        $intermed = File::Spec->catdir($intermed, $d);
        push @expected_subdirs, $intermed;
    }
    for my $d (@expected_subdirs) {
        ok(! -d $d, "Directory $d does not yet exist");
    }
    my $expected_file = File::Spec->catfile($expected_subdirs[-1], $fname);
    ok(! -f $expected_file, "File      $expected_file does not yet exist");

    my ($from, $to);
    $from = $tdirs[0];
    $to = $tdirs[1];
    $rv = dircopy($from, $to);
    ok(defined $rv, "dircopy() returned defined value");
    for my $d (@expected_subdirs) {
        ok(-d $d, "Directory $d has been created");
    }
    ok(-f $expected_file, "File      $expected_file has been created");
}

{
    note("Copying of subdirs containing 1 file at non-bottom level");
    my $topdir = tempdir(CLEANUP => 1);
    my @tdir_names = ('xray', 'yeller');
    my @tdirs = touch_directories_and_test($topdir, \@tdir_names);
    my @subdir_names = ('alpha', 'beta', 'gamma');
    my $ldir = touch_left_path_and_test($tdirs[0], @subdir_names);
    my $fname = 'foo';
    my $f1 = create_tfile(File::Spec->catdir($tdirs[0], @subdir_names[0..1]), $fname);
    ok(-f $f1, "File      $f1 created at non-bottom level");
    my @expected_subdirs = ();
    my $intermed = $tdirs[1];
    for my $d (@subdir_names) {
        $intermed = File::Spec->catdir($intermed, $d);
        push @expected_subdirs, $intermed;
    }
    for my $d (@expected_subdirs) {
        ok(! -d $d, "Directory $d does not yet exist");
    }
    my $expected_file = File::Spec->catfile($expected_subdirs[-2], $fname);
    ok(! -f $expected_file, "File      $expected_file does not yet exist");

    my ($from, $to);
    $from = $tdirs[0];
    $to = $tdirs[1];
    $rv = dircopy($from, $to);
    ok(defined $rv, "dircopy() returned defined value");
    for my $d (@expected_subdirs) {
        ok(-d $d, "Directory $d has been created");
    }
    ok(-f $expected_file, "File      $expected_file has been created");
}

{
    my $tdir = tempdir(CLEANUP => 1);
    my $tdir2 = tempdir(CLEANUP => 1);
    my $f1 = create_tfile($tdir, 'foo');
    my $f2 = create_tfile($tdir, 'bar');

    $from = $tdir;
    $to = $tdir2;
    $rv = dircopy($from, $to);
    ok(defined $rv, "dircopy() returned defined value");

    $from = "$tdir/*";
    $to = $tdir2;
    $rv = dircopy($from, $to);
    ok(defined $rv, "dircopy() returned defined value when first argument ends with '/*'");
}

my @dirnames = ( qw|
    able baker camera dogtag elmore
    fargo golfer hatrack impish jolt
    karma lily mandate namesake oleo
    partner quorum robot sterling tamarack
    ultra victor windy xray yellow zebra
| );

{
    note("Basic tests of File::Copy::Recursive::Reduced::dircopy()");
    basic_dircopy_tests(@dirnames);
    SKIP: {
        skip "System does not support symlinks", 13
            unless $File::Copy::Recursive::Reduced::CopyLink;

        note("Copy directory which holds symlinks");
        mixed_block();
        mixed_imperfect_block();
    }
}

SKIP: {
    skip "Set PERL_AUTHOR_TESTING to true to compare with FCR::dircopy()", 26
        unless $ENV{PERL_AUTHOR_TESTING};

    my $rv = eval { require File::Copy::Recursive; };
    SKIP: {
        skip "Must install File::Copy::Recursive for certain tests", 26
            unless $rv;
        no warnings ('redefine');
        local *dircopy = \&File::Copy::Recursive::dircopy;
        use warnings;

        note("COMPARISON: Basic tests of File::Copy::Recursive::dircopy()");
        basic_dircopy_tests(@dirnames);
        SKIP: {
            skip "System does not support symlinks",  6
                unless $File::Copy::Recursive::Reduced::CopyLink;

            note("Copy directory which holds symlinks");
            mixed_block();
        }
    }
}

#################### SUBROUTINES ####################

sub basic_dircopy_tests {
    my @dirnames = @_;
    {
        note("Multiple directories; no files");
        my $topdir = tempdir(CLEANUP => 1);
        my ($tdir, $tdir2, $old, $oldtree, $new, $rv, $expected);
        my @subdirs = @dirnames[0..4];

        # Prepare left side
        ($old, $oldtree) = prepare_left_side_directories($topdir, 'alpha', \@subdirs);

        # Prepare right side
        $tdir2  = File::Spec->catdir($topdir, 'beta');
        $expected   = File::Spec->catdir($tdir2, @subdirs);

        # Test
        my ($from, $to) = ($old, $tdir2);
        $rv = dircopy($from, $to);
        ok($rv, "dircopy() returned true value");
        ok(-d $tdir2, "dircopy(): directory $tdir2 created");
        ok(-d $expected, "dircopy(): directory $expected created");
    }

    {
        note("Multiple directories; files at bottom level");
        my $topdir = tempdir(CLEANUP => 1);
        my ($tdir, $tdir2, $old, $oldtree, $new, $rv, $expected);
        my (@basenames);
        my @subdirs = @dirnames[5..7];

        # Prepare left side
        ($old, $oldtree) = prepare_left_side_directories($topdir, 'alpha', \@subdirs);
        @basenames = qw| foo bar |;
        for my $b (@basenames) {
            my $f = touch_a_file_and_test(File::Spec->catfile($oldtree, $b));
        }

        # Prepare right side
        $tdir2  = File::Spec->catdir($topdir, 'beta');
        $expected   = File::Spec->catdir($tdir2, @subdirs);

        # Test
        my ($from, $to) = ($old, $tdir2);
        $rv = dircopy($from, $to);
        ok(-d $expected, "dircopy(): directory $expected created");
        # test for creation of files
        for my $b (@basenames) {
            my $f = File::Spec->catfile($expected, $b);
            ok(-f $f, "dircopy(): file $f created");
        }
    }

    {
        note("Multiple directories; files at intermediate levels");
        my $topdir = tempdir(CLEANUP => 1);
        my ($tdir, $tdir2, $old, $oldtree, $new, $rv, $expected);
        my @subdirs = @dirnames[8..11];

        # Prepare left side
        ($old, $oldtree) = prepare_left_side_directories($topdir, 'alpha', \@subdirs);
        my $f = File::Spec->catfile(@subdirs[0..1], 'foo');
        my $g = File::Spec->catfile(@subdirs[0..2], 'bar');
        for my $h ($f, $g) {
            touch_a_file_and_test(File::Spec->catfile($old, $h));
        }

        # Prepare right side
        $tdir2  = File::Spec->catdir($topdir, 'beta');
        $expected   = File::Spec->catdir($tdir2, @subdirs);
        my @expected_files = (
            File::Spec->catfile($tdir2, @subdirs[0..1], 'foo'),
            File::Spec->catfile($tdir2, @subdirs[0..2], 'bar'),
        );

        # Test
        my ($from, $to) = ($old, $tdir2);
        $rv = dircopy($from, $to);
        ok($rv, "dircopy() returned true value");
        ok(-d $expected, "dircopy(): directory $expected created");
        # test for creation of files
        for my $b (@expected_files) {
            ok(-f $b, "dircopy(): file $b created");
        }
    }
} # END definition of basic_dircopy_tests()

sub mixed_block {
    my $tdir = tempdir(CLEANUP => 1);
    my $old = File::Spec->catdir($tdir, 'old');
    mkpath $old or die "Unable to mkpath $old";
    ok(-d $old, "Created $old for testing");
    my $rv = make_mixed_directory($old);
    ok($rv, "make_mixed_directory() returned true value");
    is(ref($rv), 'HASH', "make_mixed_directory() returned hashref");
    my $counts = {
        dirs => scalar @{$rv->{dirs}},
        files => scalar @{$rv->{files}},
        symlinks => scalar @{$rv->{symlinks}},
    };
    my $exp = {
        dirs => 9,
        files => 6,
        symlinks => 3,
    };
    is_deeply($counts, $exp,
        "Got expected number of directories, files and symlinks for testing");

    my $new = File::Spec->catdir($tdir, 'new');
    $rv = dircopy($old, $new) or die "Unable to dircopy";
    ok(defined $rv, "dircopy() returned defined value");
    my %seen = ();
    my $wanted = sub {
        # NOTE: File::Find returns path with forward slashes on Windows
        #  so we need to convert to canonical path before comparing
        my $name = File::Spec->canonpath($File::Find::name);
        unless ($name eq $new) {
            $seen{dirs}{$name}++ if -d $name;
            if (-l $name) {
                $seen{symlinks}{$name}++;
            }
            elsif (-f $name) {
                $seen{files}{$name}++;
            }
        }
    };
    find($wanted, $new);
    #require Data::Dump;
    #Data::Dump::pp(\%seen);
    my $created_counts = {
        dirs => scalar keys %{$seen{dirs}},
        files => scalar keys %{$seen{files}},
        symlinks => scalar keys %{$seen{symlinks}},
    };
    is_deeply($created_counts, $counts,
        "Got expected number of directories, files and symlinks by copying");
} # END definition of mixed_block()

sub mixed_imperfect_block {
    my $tdir = tempdir(CLEANUP => 1);
    my $old = File::Spec->catdir($tdir, 'old');
    mkpath $old or die "Unable to mkpath $old";
    ok(-d $old, "Created $old for testing");
    my $rv = make_imperfect_mixed_directory($old);
    ok($rv, "make_imperfect_mixed_directory() returned true value");
    is(ref($rv), 'HASH', "make_imperfect_mixed_directory() returned hashref");
    my $counts = {
        dirs => scalar @{$rv->{dirs}},
        files => scalar @{$rv->{files}},
        symlinks => scalar @{$rv->{symlinks}},
    };
    my $exp = {
        dirs => 9,
        files => 5,
        symlinks => 3,
    };
    is_deeply($counts, $exp,
        "Got expected number of directories, files and symlinks for testing");

    my $new = File::Spec->catdir($tdir, 'new');
    my $stderr = capture_stderr { $rv = dircopy($old, $new) or die "Unable to dircopy"; };
    ok(defined $rv, "dircopy() returned defined value");
    like(
        $stderr,
        qr/Copying a symlink.*?whose target does not exist/,
        "Got expected warning when copying a symlink whose target does not exist"
    );

    my %seen = ();
    my $wanted = sub {
        # NOTE: File::Find returns path with forward slashes on Windows
        #  so we need to convert to canonical path before comparing
        my $name = File::Spec->canonpath($File::Find::name);
        unless ($name eq $new) {
            $seen{dirs}{$name}++ if -d $name;
            if (-l $name) {
                $seen{symlinks}{$name}++;
            }
            elsif (-f $name) {
                $seen{files}{$name}++;
            }
        }
    };
    find($wanted, $new);
    #require Data::Dump;
    #Data::Dump::pp(\%seen);
    my $created_counts = {
        dirs => scalar keys %{$seen{dirs}},
        files => scalar keys %{$seen{files}},
        symlinks => scalar keys %{$seen{symlinks}},
    };
    is_deeply($created_counts, $counts,
        "Got expected number of directories, files and symlinks by copying");
} # END definition of mixed_imperfect_block()

