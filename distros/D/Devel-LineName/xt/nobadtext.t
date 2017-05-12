# Check for some things that shouldn't be in release quality code.

use strict;
use warnings;

use autodie;
use Test::More;
use File::Find::Rule;
use File::Slurp;

my @files = File::Find::Rule->file()->in(qw(
    Build.PL lib t xt Changes MANIFEST.SKIP README
));

plan tests => scalar @files;

my %not_bad_line = map {$_ => 1} split /\n/, <<'END';
warn "warning from deep in a subtest\n";
warn "this is a warning\n";
END

foreach my $file (@files) {
    my @bad;
    open my $fh, "<", $file;
    while (<$fh>) {
        s/^\s*//;
        chomp;
        next if $not_bad_line{$_};

        unless ($file =~ /nobadtext\.t/) {
            /FIXME/ and push @bad, "FIXME at line $.";
            /XXX/   and push @bad, "XXX at line $.";
            /\bwarn\b/ and push @bad, "warn at line $.";
            /^=pod/ and push @bad, "block commented code at line $.";
        }

        /\s\z/ and push @bad, "trailing whitespace at line $.";
        /\r/   and push @bad, "literal \\r at line $.";
        /\t/   and push @bad, "tab at line $."; # I indent with spaces

        /^\s*\#.*;\s*$/ and push @bad, "commented out code at line $.";

        if ($file eq "Changes") {
            /\?\?\?/ and push @bad, "??? at line $.";
        }
    }
    unless ( ok @bad == 0, "no bad text in $file" ) {
        foreach my $bad (@bad) {
            diag $bad;
        }
    }
}

