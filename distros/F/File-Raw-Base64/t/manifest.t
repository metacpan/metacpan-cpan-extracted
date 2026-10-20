#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

unless ( $ENV{RELEASE_TESTING} ) {
    plan( skip_all => "Author tests not required for installation" );
}

my $min_tcm = 0.9;
eval "use Test::CheckManifest $min_tcm";
plan skip_all => "Test::CheckManifest $min_tcm required" if $@;

# What a build leaves in the tree is not shipped: objects, bootstraps, the
# C that xsubpp writes from each .xs, ExtUtils::Depends' Install/Files.pm.
my @xs_c = map { (my $c = $_) =~ s/\.xs\z/.c/; qr/\Q$c\E\z/ } glob '*.xs';
ok_manifest({ filter => [ qr/\.(?:o|bs)\z/, @xs_c, qr{/Install/Files\.pm\z}, qr{/MANIFEST\.bak\z} ] });
