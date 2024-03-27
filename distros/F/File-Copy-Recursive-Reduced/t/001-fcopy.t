# -*- perl -*-
# t/001-fcopy.t - tests of fcopy() method
use strict;
use warnings;

use Test::More tests => 85;
use File::Copy::Recursive::Reduced qw( fcopy );

use Capture::Tiny qw(capture_stderr);
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
|);

my ($from, $to, $rv);

note("fcopy(): Test faulty or inappropriate arguments");

$rv = fcopy();
ok(! defined $rv, "fcopy() returned undef when not provided correct number of arguments");

$rv = fcopy('foo');
ok(! defined $rv, "fcopy() returned undef when not provided correct number of arguments");

$rv = fcopy('foo', 'bar', 'baz', 'bletch');
ok(! defined $rv, "fcopy() returned undef when not provided correct number of arguments");

$rv = fcopy(undef, 'foo');
ok(! defined $rv, "fcopy() returned undef when first argument was undefined");

$rv = fcopy('foo', undef);
ok(! defined $rv, "fcopy() returned undef when second argument was undefined");

$rv = fcopy('foo', 'foo');
ok(! defined $rv, "fcopy() returned undef when provided 2 identical arguments");

SKIP: {
    skip "System does not support hard links", 3
        unless $File::Copy::Recursive::Reduced::Link;
    my $tdir = tempdir( CLEANUP => 1 );
    my ($old, $new) = create_tfile_and_name_for_new_file_in_same_dir($tdir);
    my $rv = link($old, $new) or die "Unable to link: $!";
    ok($rv, "Able to hard link $old and $new");
    my $stderr = capture_stderr { $rv = fcopy($old, $new); };
    ok(! defined $rv,
        "fcopy() returned undef when provided arguments with identical dev and ino");
    SKIP: {
        skip 'identical-dev-ino check not applicable on Windows', 1
            if ($^O eq 'MSWin32') ;
        like($stderr, qr/\Q$old and $new are identical\E/,
            "fcopy(): got expected warning when provided arguments with identical dev and ino");
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
    ok(-l $symlink, "fcopy(): $symlink is indeed a symlink");
    is(readlink($symlink), $old, "Symlink $symlink points to $old");
    $new = File::Spec->catfile($tdir, 'new');
    $rv = fcopy($symlink, $new);
    ok(defined $rv, "fcopy() returned defined value when copying from symlink");
    ok($rv, "fcopy() returned true value when copying from symlink");
    ok(-f $new, "fcopy(): $new is a file");
    ok(-l $new, "fcopy(): but $new is also another symlink");

    my ($xold, $xnew, $xsymlink, $stderr);
    $xold = create_tfile($tdir);
    $xsymlink = File::Spec->catfile($tdir, 'xsym');
    $rv = symlink($xold, $xsymlink)
        or die "Unable to symlink $xsymlink to target $xold for testing: $!";
    ok(-l $xsymlink, "fcopy(): $xsymlink is indeed a symlink");
    is(readlink($xsymlink), $xold, "Symlink $xsymlink points to $xold");
    $xnew = File::Spec->catfile($tdir, 'xnew');
    unlink $xold or die "Unable to unlink $xold during testing: $!";
    $stderr = capture_stderr { $rv = fcopy($xsymlink, $xnew); };
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
    $rv = fcopy($tdir, $new);
    ok(! defined $rv,
        "RTC 123964: fcopy() returned undefined value when first argument was a directory");
}

note("fcopy(): Test good arguments");

sub basic_tests {

    note("Copy file within existing same directory, new basename");
    my ($tdir, $old, $new, $rv, $stderr);
    $tdir = tempdir( CLEANUP => 1 );
    ($old, $new) = create_tfile_and_name_for_new_file_in_same_dir($tdir);

    note("AAA: 1st: $old");
    note("     2nd: $new");
    $rv = fcopy($old, $new);
    ok($rv, "fcopy() returned true value: $rv");
    ok(-f $new, "$old copied to $new, which is file");

    note("Copy file to existing different directory, same basename");
    my ($tdir2, $basename, $expected_new_file);
    $tdir2 = tempdir( CLEANUP => 1 );
    $basename = 'thirdfile';
    $old = create_tfile($tdir, $basename);
    $expected_new_file = File::Spec->catfile($tdir2, $basename);
    note("BBB: 1st: $old");
    note("     2nd: $tdir2");
    $rv = fcopy($old, $tdir2);
    ok($rv, "fcopy() returned true value: $rv");
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
    $rv = fcopy($old, $expected_new_file);
    ok($rv, "fcopy() returned true value: $rv");
    ok(-f $expected_new_file, "$old copied to $expected_new_file, which is file");
    return 1;
}

sub more_basic_tests {
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

    note("Case 1: " . q|fcopy('/path/to/filename', '/path/to/newfile');|);
    $base = 'file1';
    $orig = File::Spec->catfile($adir, $base);
    $newbase = 'newfile';
    $new = $expect = File::Spec->catfile($adir, $newbase);
    ok(! -e $expect, "$expect does not yet exist");
    $rv = fcopy($orig, $new);
    ok(defined $rv, "fcopy() returned defined value");
    ok(-f $expect, "$expect has been created");

    note("Case 2: " . q|fcopy('/path/to/filename', '/path/to/existing/directory');|);
    $base = 'file2';
    $orig = File::Spec->catfile($adir, $base);
    $new = $bdir;
    $expect = File::Spec->catfile($bdir, $base);
    ok(! -e $expect, "$expect does not yet exist");
    $rv = fcopy($orig, $new);
    ok(defined $rv, "fcopy() returned defined value");
    ok(-f $expect, "$expect has been created");

    note("Case 3: " . q|fcopy('/path/to/filename', '/path/not/yet/existing/directory/filename')|);
    $base = 'file3';
    $orig = File::Spec->catfile($adir, $base);
    @subdirs = qw( alpha beta );
    $newdir = File::Spec->catdir($bdir, @subdirs);
    $new = $expect = File::Spec->catfile($newdir, $base);
    ok(! -e $expect, "$expect does not yet exist");
    $rv = fcopy($orig, $new);
    ok(defined $rv, "fcopy() returned defined value");
    ok(-f $expect, "$expect has been created");
    {
        my $interdir = $bdir;
        for my $d (@subdirs) {
            $interdir = File::Spec->catdir($interdir, $d);
            ok(-d $interdir, "Intermediate directory $interdir created");
        }
    }

    note("Case 4: " . q|fcopy('/path/to/filename', #'/path/not/yet/existing/directory/newfile');|);
    $base = 'file4';
    $orig = File::Spec->catfile($adir, $base);
    @subdirs = qw( gamma delta );
    $newdir = File::Spec->catdir($bdir, @subdirs);
    $newbase = 'newfile';
    $new = $expect = File::Spec->catfile($newdir, $newbase);
    ok(! -e $expect, "$expect does not yet exist");
    $rv = fcopy($orig, $new);
    ok(defined $rv, "fcopy() returned defined value");
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
    note("Basic tests of fcopy()");
    basic_tests();

    my $tdir = tempdir(CLEANUP => 1);
    my $adir = "$tdir/albemarle";
    my $bdir = "$tdir/beverly";
    more_basic_tests($tdir, $adir, $bdir);
}

SKIP: {
    skip "Set PERL_AUTHOR_TESTING to true to compare with FCR::fcopy()", 29
        unless $ENV{PERL_AUTHOR_TESTING};

    my $rv = eval { require File::Copy::Recursive; };
    SKIP: {
        skip "Must install File::Copy::Recursive for certain tests", 29
            unless $rv;
        no warnings ('redefine');
        local *fcopy = \&File::Copy::Recursive::fcopy;
        use warnings;

        note("COMPARISON: Basic tests of File::Copy::Recursive::fcopy()");

        basic_tests();

        my $tdir = tempdir(CLEANUP => 1);
        my $adir = "$tdir/albemarle";
        my $bdir = "$tdir/beverly";
        more_basic_tests($tdir, $adir, $bdir);
    }
}

{
    note("Tests from FCR t/01.legacy.t");
    my ($tdir, $old, $new, $symlink, $rv);
    my $tmpd = get_fresh_tmp_dir();
    ok(-d $tmpd, "$tmpd exists");

    $rv = fcopy( "$tmpd/orig/data", "$tmpd/fcopy" );
    is(
        path("$tmpd/orig/data")->slurp,
        path("$tmpd/fcopy")->slurp,
        "fcopy() defaults as expected when target does not exist"
    );

    path("$tmpd/fcopyexisty")->spew("oh hai");
    my @fcopy_rv = fcopy( "$tmpd/orig/data", "$tmpd/fcopyexisty");
    is(
        path("$tmpd/orig/data")->slurp,
        path("$tmpd/fcopyexisty")->slurp,
        "fcopy() defaults as expected when target does exist"
    );

    # This is the test that fails on FreeBSD
    # https://rt.cpan.org/Ticket/Display.html?id=123964
    $rv = fcopy( "$tmpd/orig", "$tmpd/fcopy" );
    ok(!$rv, "RTC 123964: fcopy() returns false if source is a directory");
}

{
    note("Tests using FCR's fcopy() from CPAN::Reporter's test suite");
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
        fcopy($sample_history_file, $history_file);
        ok( -f $history_file, "copied sample old history file to config directory");
    }
}

__END__
