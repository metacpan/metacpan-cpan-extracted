use strict;
use warnings;

use Test::More;
use Dir::Iterate;

sub test_it(&$);
sub load_manifest;

my $num_tests = 5;

my @manifest = load_manifest;

plan tests => $num_tests * @manifest + 1;

ok(scalar @manifest, "Prepping: got the manifest");

test_it { 1 } "All";
test_it { 0 } "None";
test_it { -s % 2 } "Mix";
test_it { -d } "Is directory";
test_it { -f } "Is file";

sub test_it(&$) {
    my($pred, $description) = @_;

    my @dir_results = grepdir { $pred->() } '.';
    my @reg_results = grep    { $pred->() } @manifest;
    
    my %dir_results = map { $_ => 1 } @dir_results;
    my %reg_results = map { $_ => 1 } @reg_results;
    
    for my $file(@manifest) {
        is(
            $dir_results{$file},
            $reg_results{$file},
            "$description ($file)"
        );
    }
}

sub load_manifest {
    use File::Spec;
    use ExtUtils::Manifest;

    chdir("..") or die unless -e "MANIFEST";
    
    return map { File::Spec->rel2abs($_) } keys %{ExtUtils::Manifest::maniread()}
}
