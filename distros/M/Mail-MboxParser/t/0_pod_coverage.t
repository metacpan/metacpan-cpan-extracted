eval "use Test::Pod::Coverage";
if ($@) {
    print "1..0 # Skip Test::Pod::Coverage not installed\n";
    exit;
} 

my $ARGS = {
    also_private    => [ qr/_(old|new)$/, qr/^init$/, qr/^parts$/ ],
    trustme	    => [ qr/^(?:error|log|new|reset_last)$/ ],
};

all_pod_coverage_ok( $ARGS );
