# -*- perl -*-
# t/003-rcopy.t - tests of rcopy() method
use strict;
use warnings;

use Test::More tests => 188;
use File::Copy::Recursive::Reduced qw( rcopy );

use Capture::Tiny qw(capture_stderr);
use File::Find;
use File::Path qw(mkpath);
use File::Spec;
use File::Temp qw(tempdir);
use Path::Tiny;
use lib qw( t/lib );
use MockHomeDir;
use Helper ( qw|
    create_tfile_and_name_for_new_file_in_same_dir
    create_tfile
    get_fresh_tmp_dir
    create_tsubdir
    touch_a_file_and_test
    touch_directories_and_test
    touch_left_path_and_test
    prepare_left_side_directories
    make_mixed_directory
|);

my ($from, $to, $rv);

note("rcopy(): Test faulty or inappropriate arguments");

$rv = rcopy();
ok(! defined $rv, "rcopy() returned undef when not provided correct number of arguments");

$rv = rcopy('foo');
ok(! defined $rv, "rcopy() returned undef when not provided correct number of arguments");

$rv = rcopy('foo', 'bar', 'baz', 'bletch');
ok(! defined $rv, "rcopy() returned undef when not provided correct number of arguments");

$rv = rcopy(undef, 'foo');
ok(! defined $rv, "rcopy() returned undef when first argument was undefined");

$rv = rcopy('foo', undef);
ok(! defined $rv, "rcopy() returned undef when second argument was undefined");

$rv = rcopy('foo', 'foo');
ok(! defined $rv, "rcopy() returned undef when provided 2 identical arguments");

SKIP: {
    skip "System does not support hard links", 3
        unless $File::Copy::Recursive::Reduced::Link;
    my $tdir = tempdir( CLEANUP => 1 );
    my ($old, $new) = create_tfile_and_name_for_new_file_in_same_dir($tdir);
    my $rv = link($old, $new) or die "Unable to link: $!";
    ok($rv, "Able to hard link $old and $new");
    my $stderr = capture_stderr { $rv = rcopy($old, $new); };
    ok(! defined $rv,
        "rcopy() returned undef when provided arguments with identical dev and ino");
    SKIP: {
        skip 'identical-dev-ino check not applicable on Windows', 1
            if ($^O eq 'MSWin32') ;
        like($stderr, qr/\Q$old and $new are identical\E/,
            "rcopy(): got expected warning when provided arguments with identical dev and ino");
    }
}

SKIP: {
    skip "System does not support symlinks", 11
        unless $File::Copy::Recursive::Reduced::CopyLink;

    # System supports symlinks
    my ($tdir, $old, $new, $symlink, $rv);
    $tdir = tempdir( CLEANUP => 1 );
    $old = create_tfile($tdir);
    $symlink = File::Spec->catfile($tdir, 'sym');
    $rv = symlink($old, $symlink)
        or die "Unable to symlink $symlink to target $old for testing: $!";
    ok(-l $symlink, "rcopy(): $symlink is indeed a symlink");
    is(readlink($symlink), $old, "Symlink $symlink points to $old");
    $new = File::Spec->catfile($tdir, 'new');
    $rv = rcopy($symlink, $new);
    ok(defined $rv, "fcopy() returned defined value when copying from symlink");
    ok($rv, "fcopy() returned true value when copying from symlink");
    ok(-f $new, "fcopy(): $new is a file");
    ok(-l $new, "fcopy(): but $new is also another symlink");

    my ($xold, $xnew, $xsymlink, $stderr);
    $xold = create_tfile($tdir);
    $xsymlink = File::Spec->catfile($tdir, 'xsym');
    $rv = symlink($xold, $xsymlink)
        or die "Unable to symlink $xsymlink to target $xold for testing: $!";
    ok(-l $xsymlink, "rcopy(): $xsymlink is indeed a symlink");
    is(readlink($symlink), $old, "Symlink $symlink points to $old");
    $xnew = File::Spec->catfile($tdir, 'xnew');
    unlink $xold or die "Unable to unlink $xold during testing: $!";
    $stderr = capture_stderr { $rv = rcopy($xsymlink, $xnew); };
    ok(defined $rv, "fcopy() returned defined value when copying from symlink");
    ok($rv, "fcopy() returned true value when copying from symlink");
    like($stderr, qr/Copying a symlink \(\Q$xsymlink\E\) whose target does not exist/,
        "fcopy(): Got expected warning when copying from symlink whose target does not exist");
}

{
    my ($tdir, $tdir2, $old, $new, $rv);
    $tdir   = tempdir( CLEANUP => 1 );
    $tdir2  = tempdir( CLEANUP => 1 );
    $new = create_tfile($tdir2, 'new_file');
    $rv = rcopy($tdir, $new);
    ok(! defined $rv,
        "RTC 123964: rcopy() returned undefined value when first argument was a directory");
}

note("rcopy(): Test good arguments");

sub basic_rcopy_file_tests {

    note("Copy file within existing same directory, new basename");
    my ($tdir, $old, $new, $rv, $stderr);
    $tdir = tempdir( CLEANUP => 1 );
    ($old, $new) = create_tfile_and_name_for_new_file_in_same_dir($tdir);

    note("AAA: 1st: $old");
    note("     2nd: $new");
    $rv = rcopy($old, $new);
    ok($rv, "rcopy() returned true value: $rv");
    ok(-f $new, "$old copied to $new, which is file");

    note("Copy file to existing different directory, same basename");
    my ($tdir2, $basename, $expected_new_file);
    $tdir2 = tempdir( CLEANUP => 1 );
    $basename = 'thirdfile';
    $old = create_tfile($tdir, $basename);
    $expected_new_file = File::Spec->catfile($tdir2, $basename);
    note("BBB: 1st: $old");
    note("     2nd: $tdir2");
    $rv = rcopy($old, $tdir2);
    ok($rv, "rcopy() returned true value: $rv");
    ok(-f $expected_new_file, "$old copied to $expected_new_file, which is file");

    note("Copy file to different directory not yet existing;");
    note("  basename must be explicitly provided at end of 2nd argument");
    my (@subdirs, $newdir);
    $basename = 'fourth_file';
    $old = create_tfile($tdir, $basename);
    @subdirs = ('alpha', 'beta', 'gamma');
    $newdir = File::Spec->catdir($tdir2, @subdirs);
    $expected_new_file = File::Spec->catfile($newdir, $basename);
    note("CCC: 1st: $old");
    note("     2nd: $expected_new_file");
    $rv = rcopy($old, $expected_new_file);
    ok($rv, "rcopy() returned true value: $rv");
    ok(-f $expected_new_file, "$old copied to $expected_new_file, which is file");
    return 1;
}

sub more_basic_rcopy_file_tests {
    my ($tdir, $adir, $bdir) = @_;
    mkdir($adir);
    mkdir($bdir);
    for my $d ($tdir, $adir, $bdir) {
        ok(-d $d, "$d located") or die "Can't find $d";
    }
    for (1..4) {
        my $f = 'file'. $_;
        my $af = "$adir/$f";;
        open my $OUT, '>', $af or die "Unable to open to write";
        print $OUT "\n";
        close $OUT or die "Unable to close after write";
        ok(-f $af, "Created dummy file $af");
    }

    my ($base, $orig, $newbase, $new, $expect, $rv, $newdir, @subdirs);

    note("Case 1: " . q|rcopy('/path/to/filename', '/path/to/newfile');|);
    $base = 'file1';
    $orig = File::Spec->catfile($adir, $base);
    $newbase = 'newfile';
    $new = $expect = File::Spec->catfile($adir, $newbase);
    ok(! -e $expect, "$expect does not yet exist");
    $rv = rcopy($orig, $new);
    ok(defined $rv, "rcopy() returned defined value");
    ok(-f $expect, "$expect has been created");

    note("Case 2: " . q|rcopy('/path/to/filename', '/path/to/existing/directory');|);
    $base = 'file2';
    $orig = File::Spec->catfile($adir, $base);
    $new = $bdir;
    $expect = File::Spec->catfile($bdir, $base);
    ok(! -e $expect, "$expect does not yet exist");
    $rv = rcopy($orig, $new);
    ok(defined $rv, "rcopy() returned defined value");
    ok(-f $expect, "$expect has been created");

    note("Case 3: " . q|rcopy('/path/to/filename', '/path/not/yet/existing/directory/filename')|);
    $base = 'file3';
    $orig = File::Spec->catfile($adir, $base);
    @subdirs = qw( alpha beta );
    $newdir = File::Spec->catdir($bdir, @subdirs);
    $new = $expect = File::Spec->catfile($newdir, $base);
    ok(! -e $expect, "$expect does not yet exist");
    $rv = rcopy($orig, $new);
    ok(defined $rv, "rcopy() returned defined value");
    ok(-f $expect, "$expect has been created");
    {
        my $interdir = $bdir;
        for my $d (@subdirs) {
            $interdir = File::Spec->catdir($interdir, $d);
            ok(-d $interdir, "Intermediate directory $interdir created");
        }
    }

    note("Case 4: " . q|rcopy('/path/to/filename', #'/path/not/yet/existing/directory/newfile');|);
    $base = 'file4';
    $orig = File::Spec->catfile($adir, $base);
    @subdirs = qw( gamma delta );
    $newdir = File::Spec->catdir($bdir, @subdirs);
    $newbase = 'newfile';
    $new = $expect = File::Spec->catfile($newdir, $newbase);
    ok(! -e $expect, "$expect does not yet exist");
    $rv = rcopy($orig, $new);
    ok(defined $rv, "rcopy() returned defined value");
    ok(-f $expect, "$expect has been created");
    {
        my $interdir = $bdir;
        for my $d (@subdirs) {
            $interdir = File::Spec->catdir($interdir, $d);
            ok(-d $interdir, "Intermediate directory $interdir created");
        }
    }
    return 1;
}

{
    note("Basic tests of rcopy()");
    basic_rcopy_file_tests();

    my $tdir = tempdir(CLEANUP => 1);
    my $adir = "$tdir/albemarle";
    my $bdir = "$tdir/beverly";
    more_basic_rcopy_file_tests($tdir, $adir, $bdir);
}

SKIP: {
    skip "Set PERL_AUTHOR_TESTING to true to compare with FCR::rcopy()", 29
        unless $ENV{PERL_AUTHOR_TESTING};

    my $rv = eval { require File::Copy::Recursive; };
    SKIP: {
        skip "Must install File::Copy::Recursive for certain tests", 29
            unless $rv;
        no warnings ('redefine');
        local *rcopy = \&File::Copy::Recursive::rcopy;
        use warnings;

        note("COMPARISON: Basic tests of File::Copy::Recursive::rcopy()");

        basic_rcopy_file_tests();

        my $tdir = tempdir(CLEANUP => 1);
        my $adir = "$tdir/albemarle";
        my $bdir = "$tdir/beverly";
        more_basic_rcopy_file_tests($tdir, $adir, $bdir);
    }
}

{
    note("Tests from FCR t/01.legacy.t");
    my ($tdir, $old, $new, $symlink, $rv);
    my $tmpd = get_fresh_tmp_dir();
    ok(-d $tmpd, "$tmpd exists");

    $rv = rcopy( "$tmpd/orig/data", "$tmpd/rcopy" );
    is(
        path("$tmpd/orig/data")->slurp,
        path("$tmpd/rcopy")->slurp,
        "rcopy() defaults as expected when target does not exist"
    );

    path("$tmpd/rcopyexisty")->spew("oh hai");
    my @rcopy_rv = rcopy( "$tmpd/orig/data", "$tmpd/rcopyexisty");
    is(
        path("$tmpd/orig/data")->slurp,
        path("$tmpd/rcopyexisty")->slurp,
        "rcopy() defaults as expected when target does exist"
    );

    # This is the test that fails on FreeBSD
    # https://rt.cpan.org/Ticket/Display.html?id=123964
    $rv = rcopy( "$tmpd/orig", "$tmpd/rcopy" );
    ok(!$rv, "RTC 123964: rcopy() returns false if source is a directory");
}

{
    note("Tests using FCR's rcopy() from CPAN::Reporter's test suite");
    # t/66_have_tested.t
    # t/72_rename_history.t
    my $config_dir = File::Spec->catdir( MockHomeDir::home_dir, ".cpanreporter" );
    my $config_file = File::Spec->catfile( $config_dir, "config.ini" );
    my $history_file = File::Spec->catfile( $config_dir, "reports-sent.db" );
    my $sample_history_file = File::Spec->catfile(qw/t history reports-sent-longer.db/);
    mkpath( $config_dir );
    ok( -d $config_dir, "temporary config dir created" );

    # CPAN::Reporter:If old history exists, convert it
    # I'm not really sure what the point of this test is.
    SKIP: {
        skip "$sample_history_file does not exist", 1
            unless -e $sample_history_file;
        rcopy($sample_history_file, $history_file);
        ok( -f $history_file, "copied sample old history file to config directory");
    }
}

{
    note("rcopy(): Argument validation");

    $rv = rcopy();
    ok(! defined $rv, "rcopy() returned undef when not provided correct number of arguments");

    $rv = rcopy('foo');
    ok(! defined $rv, "rcopy() returned undef when not provided correct number of arguments");

    $rv = rcopy('foo', 'bar', 'baz', 'bletch');
    ok(! defined $rv, "rcopy() returned undef when not provided correct number of arguments");

    $rv = rcopy(undef, 'foo');
    ok(! defined $rv, "rcopy() returned undef when first argument was undefined");

    $rv = rcopy('foo', undef);
    ok(! defined $rv, "rcopy() returned undef when second argument was undefined");

    $rv = rcopy('foo', 'foo');
    ok(! defined $rv, "rcopy() returned undef when provided 2 identical arguments");

    SKIP: {
        skip "System does not support hard links", 3
            unless $File::Copy::Recursive::Reduced::Link;
        my $tdir = tempdir( CLEANUP => 1 );
        my ($old, $new) = create_tfile_and_name_for_new_file_in_same_dir($tdir);
        my $rv = link($old, $new) or die "Unable to link: $!";
        ok($rv, "Able to hard link $old and $new");
        my $stderr = capture_stderr { $rv = rcopy($old, $new); };
        ok(! defined $rv,
            "rcopy() returned undef when provided arguments with identical dev and ino");
        SKIP: {
            skip 'identical-dev-ino check not applicable on Windows', 1
                if ($^O eq 'MSWin32') ;
            like($stderr, qr/\Q$old and $new are identical\E/,
                "rcopy(): got expected warning when provided arguments with identical dev and ino");
        }
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
    $rv = rcopy($from, $to);
    ok(defined $rv, "rcopy() returned defined value");
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
    $rv = rcopy($from, $to);
    ok(defined $rv, "rcopy() returned defined value");
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
    $rv = rcopy($from, $to);
    ok(defined $rv, "rcopy() returned defined value");
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
    $rv = rcopy($from, $to);
    ok(defined $rv, "rcopy() returned defined value");
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
    $rv = rcopy($from, $to);
    ok(defined $rv, "rcopy() returned defined value");

    $from = "$tdir/*";
    $to = $tdir2;
    $rv = rcopy($from, $to);
    ok(defined $rv, "rcopy() returned defined value when first argument ends with '/*'");
}

my @dirnames = ( qw|
    able baker camera dogtag elmore
    fargo golfer hatrack impish jolt
    karma lily mandate namesake oleo
    partner quorum robot sterling tamarack
    ultra victor windy xray yellow zebra
| );

sub basic_rcopy_dir_tests {
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
        $rv = rcopy($from, $to);
        ok($rv, "rcopy() returned true value");
        ok(-d $tdir2, "rcopy(): directory $tdir2 created");
        ok(-d $expected, "rcopy(): directory $expected created");
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
        $rv = rcopy($from, $to);
        ok(-d $expected, "rcopy(): directory $expected created");
        # test for creation of files
        for my $b (@basenames) {
            my $f = File::Spec->catfile($expected, $b);
            ok(-f $f, "rcopy(): file $f created");
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
        $rv = rcopy($from, $to);
        ok($rv, "rcopy() returned true value");
        ok(-d $expected, "rcopy(): directory $expected created");
        # test for creation of files
        for my $b (@expected_files) {
            ok(-f $b, "rcopy(): file $b created");
        }
    }
} # END definition of basic_rcopy_dir_tests()

sub rcopy_mixed_block {
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
    $rv = rcopy($old, $new) or die "Unable to rcopy";
    ok(defined $rv, "rcopy() returned defined value");
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
} # END definition of rcopy_mixed_block()

{
    note("Basic tests of File::Copy::Recursive::Reduced::rcopy()");
    basic_rcopy_dir_tests(@dirnames);
    SKIP: {
        skip "System does not support symlinks",  6
            unless $File::Copy::Recursive::Reduced::CopyLink;

        note("Copy directory which holds symlinks");
        rcopy_mixed_block();
    }
}

SKIP: {
    skip "Set PERL_AUTHOR_TESTING to true to compare with FCR::rcopy()", 26
        unless $ENV{PERL_AUTHOR_TESTING};

    my $rv = eval { require File::Copy::Recursive; };
    SKIP: {
        skip "Must install File::Copy::Recursive for certain tests", 26
            unless $rv;
        no warnings ('redefine');
        local *rcopy = \&File::Copy::Recursive::rcopy;
        use warnings;

        note("COMPARISON: Basic tests of File::Copy::Recursive::rcopy()");
        basic_rcopy_dir_tests(@dirnames);
        SKIP: {
            skip "System does not support symlinks",  6
                unless $File::Copy::Recursive::Reduced::CopyLink;

            note("Copy directory which holds symlinks");
            rcopy_mixed_block();
        }
    }
}

__END__
