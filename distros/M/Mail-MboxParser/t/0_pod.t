eval "use Test::Pod";
if ($@) {
    print "1..0 # Skip Test::Pod not installed\n";
    exit;
} 
 
all_pod_files_ok();
