use strict;
use warnings;
use Test::More;
use Cwd;
use File::Spec;

my $chdir = undef;  # for when tests are run from t/ or xt/
my $dirname = (File::Spec->splitdir(cwd()))[-1];
if ( $dirname =~ m/^x?t$/ ) {
    chdir '..';
    $chdir = $dirname;
}

eval { require Test::Kwalitee; };

if ($@) {
   plan skip_all => 'Test::Kwalitee not available';
} else {
   Test::Kwalitee->import(tests => ['-has_meta_yml', '-has_manifest']);
   # No META.yml and MANIFEST check since they are created when building the distro
}

chdir $chdir if defined $chdir;  # back to t/ or xt/

# do not done_testing();
