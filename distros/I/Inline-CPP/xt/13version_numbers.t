use strict;
use warnings;

## no critic (eval)

# To enable this suite one must set the RELEASE_TESTING to a true value.
# This prevents author tests from running on a user install.

# This test verifies that all known version numbers in the distribution match.
# This is an author test, for release testing purposes.  End user doesn't need.

BEGIN { 
    use Test::More;
    if ( ! $ENV{RELEASE_TESTING} ) {
        my $msg =
            'Author Test: Set $ENV{RELEASE_TESTING} to a true value to run.';
        plan( skip_all => $msg );
    }
};

require Inline::CPP;
require Inline::CPP::Parser::RecDescent;
require Inline::CPP::Config;

use FindBin;

# Eval version numbers to eliminate underscore ambiguity in dev dists.
my $TARGET_VERSION = eval $Inline::CPP::VERSION;
my $grammar_version = eval $Inline::CPP::Parser::RecDescent::VERSION;
my $config_version  = eval $Inline::CPP::Config::VERSION;


is( $grammar_version, $TARGET_VERSION, 
    'Inline::CPP and Inline::CPP::Parser::RecDescent version numbers match.' );



is( $config_version, $TARGET_VERSION,
    'Inline::CPP::Config version matches target.'   );



# Makefile.PL's dist version, for META_MERGE.
my $makefile_pl = slurp_file( '../Makefile.PL' );
ok( $makefile_pl =~ m/^\s*my\s*\$DIST_VERSION\s*=\s*'([\d._]+)'\s*;/m,
    'Found a distribution version number in Makefile.PL' );
my $makefile_pl_version = eval $1;
is( $makefile_pl_version, $TARGET_VERSION, 
    'Makefile.PL version matches target.'  );

my $changes = slurp_file( '../Changes' );
ok( $changes =~ m/^([\d._]+)\s/m,
    'Found Inline::CPP version number in Changes' );

my $changes_version = eval $1;
is( $changes_version, $TARGET_VERSION,
    'Changes version matches target.'  );




done_testing();




sub slurp_file {
    my $rel_path = shift;
    local $/ = undef;
    open my $ifh, '<', "$FindBin::Bin/$rel_path" 
        or do{
            diag "Couldn't open $FindBin::Bin/$rel_path)";
            die $!;
        };
    my $slurp = <$ifh>;
    return $slurp;
}

