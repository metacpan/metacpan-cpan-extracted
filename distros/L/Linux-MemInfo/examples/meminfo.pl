
use Linux::MemInfo;

%hash = get_mem_info();

foreach(sort keys %hash) {
    print "$_ = $hash{$_} \n";
} 
