use strict;
use warnings;
use Test::More;
use Cwd;
use File::Spec;

my $ALSO_PRIVATE = [ ];

my $chdir = undef;  # for when tests are run from t/ or xt/
my $dirname = (File::Spec->splitdir(cwd()))[-1];
if ( $dirname =~ m/^x?t$/ ) {
    chdir '..';
    $chdir = $dirname;
}

eval { require Test::Pod::Coverage; };

if ($@) {
   plan skip_all => 'Test::Pod::Coverage not available';
} else {
   Test::Pod::Coverage->import();
   all_pod_coverage_ok( { package => 'Math::Random::MT::Perl',
                          also_private => $ALSO_PRIVATE } );
}

chdir $chdir if defined $chdir;  # back to t/ or xt/

done_testing();
