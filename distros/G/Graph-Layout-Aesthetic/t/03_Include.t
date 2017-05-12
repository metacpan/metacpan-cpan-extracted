#!/usr/bin/perl -w
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 03_Include.t'

use strict;
use warnings;
BEGIN { $^W = 1 };
use Test::More "no_plan";
use File::Temp qw(tempdir);

my @warnings;
$SIG{__WARN__} = sub { push @warnings, shift };
sub check_warnings {
    is(@warnings, 0, "No warnings");
    if (@warnings) {
        diag("Unexpected warnings:");
        diag($_) for @warnings;
    }
    @warnings = ();
}

BEGIN { use_ok('Graph::Layout::Aesthetic::Include') };

sub slurp {
    my $file = shift;
    open(my $fh, "<", $file) || die "Could not open file '$file': $!";
    local $\;
    defined(my $contents = <$fh>) || die "Unexpected early EOF from $file";
    return $contents;
}

my @files = qw(include/aesth.h include/aglo.h include/at_centroid.h include/at_node_level.h include/at_sample.h include/defines.h include/point.h typemap);
eval {

    my %files;
    $files{$_} = slurp($_) for @files;

    my $tmp_dir = tempdir(CLEANUP => 1);
    chdir($tmp_dir) || die "Could not open $tmp_dir: $!";

    for my $name (@files) {
        Graph::Layout::Aesthetic::Include::write_file($name);
          ok(-f $name, "$name is a plain file");
          my $content = slurp($name);
          is($content, $files{$name}, "Proper file contents");
          unlink($name) || die "Could not unlink $name: $!";
      }
    Graph::Layout::Aesthetic::Include::write_files;
    for my $name (@files) {
        ok(-f $name, "$name is a plain file");
        my $content = slurp($name);
        is($content, $files{$name}, "Proper file contents");
        unlink($name) || die "Could not unlink $name: $!";
    }

    # Final warnings check
    check_warnings;
};
if ($@) {
    diag($@);
    fail($@);
    exit 1;
}
pass("No errors");
