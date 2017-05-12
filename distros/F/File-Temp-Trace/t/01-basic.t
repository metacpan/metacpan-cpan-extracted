#!perl -T

package main;

use Test::More tests => 13;

BEGIN {
    use_ok( 'File::Temp::Trace' ) || print "Bail out!
";
}

use strict;

sub f2 {
    my ($tmp) = @_;
    my $fh = $tmp->tempfile();
    return $fh;
}

sub f3: skip_temp_log {
    my ($tmp) = @_;
    my $fh = $tmp->tempfile();
    return $fh;
}

sub f4 {
    my ($tmp) = @_;
    return f3($tmp);
}


{
    my $tmp = File::Temp::Trace->tempdir( log => 1 );
    ok($tmp->isa("File::Temp::Trace"), "isa");

    my $dir = "$tmp";
    # diag("dir=${dir}");

    ok(-d $dir, "created directory");

    ok($dir eq $tmp->dir);

    my $lh = $tmp->logfile;
    ok(-e $lh->filename, "logfile exists");

    my $fh1 = $tmp->tempfile();
    my $fn1 = $fh1->filename;
    ok(-e $fn1, "tempfile1 exists");
    #diag($fn1);
    ok($fn1 =~ /${dir}\/UNKNOWN-.{8}$/, "expected filename");

    # TODO test content of log

    my $fh2 = f2($tmp);
    my $fn2 = $fh2->filename;
    ok(-e $fn2, "tempfile2 exists");
    # diag($fn2);
    ok($fn2 =~ /${dir}\/main-f2-.{8}$/, "expected filename");

    # TODO test content of log

    my $fh3 = f3($tmp);
    my $fn3 = $fh3->filename;
    ok(-e $fn3, "tempfile3 exists");
    # diag($fn3);
    ok($fn3 =~ /${dir}\/UNKNOWN-.{8}$/, "expected filename");

    # TODO test content of log

    my $fh4 = f4($tmp);
    my $fn4 = $fh4->filename;
    ok(-e $fn4, "tempfile4 exists");
    # diag($fn4);
    ok($fn4 =~ /${dir}\/main-f4-.{8}$/, "expected filename");

    # TODO test content of log

}
