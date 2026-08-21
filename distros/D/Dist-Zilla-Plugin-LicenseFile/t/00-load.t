use strict;
use warnings;
use Test::More;
use File::Find::Rule;

my @pm_files = File::Find::Rule->file->name('*.pm')->in('lib');

plan tests => scalar(@pm_files);

for my $file (@pm_files) {
    (my $mod = $file) =~ s{lib/(.*)\.pm$}{$1};
    $mod =~ s{/}{::}g;
    eval "require $mod";
    is($@, '', "loaded $mod from $file");
}