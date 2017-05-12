#!perl

use 5.010;
use strict;
use warnings;

use File::ShareDir::Tarball qw(dist_dir);
use File::Slurper 'read_text';
use Ledger::Parser;
use Test::Differences;
use Test::Exception;
use Test::More 0.98;

my $dir = dist_dir('Ledger-Examples');
diag ".dat files are at $dir";

my $parser = Ledger::Parser->new;

my @files = glob "$dir/examples/*.dat";
diag explain \@files;

for my $file (@files) {
    next if $file =~ /TODO-/;
    subtest "file $file" => sub {
        if ($file =~ /invalid-/) {
            dies_ok { $parser->read_file($file) } "dies";
        } else {
            my $orig_content = read_text($file);
            my $journal;
            lives_ok { $journal = $parser->read_file($file) } "lives"
                or return;
            eq_or_diff $journal->as_string, $orig_content, "round-trip";
        };
    }
}

DONE_TESTING:
done_testing;
