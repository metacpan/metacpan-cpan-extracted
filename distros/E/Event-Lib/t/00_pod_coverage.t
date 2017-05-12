eval "use Test::Pod::Coverage 0.08";
if ($@) {
    print "1..0 # Skip Test::Pod::Coverage not installed\n";
    exit;
} 

my $ARGS = {
    also_private    => [],
    trustme	    => [ qw/constant event_init event_add event_del event_free event_get_method event_get_version/],
};

all_pod_coverage_ok( $ARGS );
