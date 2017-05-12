use strict;
use warnings;

use Test::More;
use Dir::Iterate;

sub test_it(&$);
sub load_manifest;

my $num_tests = 4;

my @manifest = load_manifest;

plan tests => $num_tests * @manifest + 1;

ok(scalar @manifest, "Prepping: got the manifest");

test_it { 1 } "Single value";
test_it { 0, 1 } "Multiple values";
test_it { () } "No value";
test_it { -e } "Getting files";

sub test_it(&$) {
    my($block, $description) = @_;

    my @dir_results = mapdir { $block->() } '.';
    my @reg_results = map    { $block->() } @manifest;
    
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
