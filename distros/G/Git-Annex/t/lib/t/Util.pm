package t::Util;

use 5.028;
use strict;
use warnings;
use parent 'Exporter';

use File::Slurp;
use File::Spec::Functions qw(rel2abs);
use File::chdir;
use File::Temp qw(tempdir);
use Try::Tiny;
use Capture::Tiny qw(capture);

our @EXPORT
  = qw( corrupt_annexed_file device_id_issues git_annex_available run_bin );

sub corrupt_annexed_file {
    my ($git, $file) = @_;

    my ($key) = $git->annex("lookupkey",       $file);
    my ($loc) = $git->annex("contentlocation", $key);
    $loc = rel2abs $loc, $git->dir;

    chmod 0777, $loc;
    append_file $loc, "bazbaz\n";
}

# on a tmpfs as commonly used with sbuild, the device IDs for files
# and directories can be different, which will cause annex-to-annex to
# refuse to hardlink.  we use this sub to skip some tests if we detect
# that.  possibly annex-to-annex should only look at the device IDs of
# files (by creating a temporary file inside $dest and looking at the
# device ID of that)
sub device_id_issues {
    local $CWD = tempdir CLEANUP => 1;
    mkdir "foo";
    write_file "bar", "bar\n";
    my $foo_id = (stat "foo")[0];
    my $bar_id = (stat "bar")[0];
    return ($foo_id != $bar_id);
}

sub git_annex_available {
    `which git-annex`;
    return !$?;
}

sub run_bin {
    (my $bin = "App::" . shift) =~ tr/-/_/;
    local @ARGV = @_;
    my ($stdout, $stderr, $exit) = capture {
        my $exit;
        # in order to simulate calling the program at the command
        # line, convert exceptions into what happens when an ordinary
        # perl script, invoked from the command line, calls 'die'
        #<<<
        try {
            $exit = $bin->main;
        } catch {
            say STDERR $_;
            $exit = 255;
        };
        #>>>
        return $exit;
    };
    my @stdout = split "\n", $stdout;
    my @stderr = split "\n", $stderr;
    return (\@stdout, \@stderr, $exit);
}

1;
