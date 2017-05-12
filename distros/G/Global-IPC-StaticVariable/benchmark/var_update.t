use strict;
use warnings;

use Benchmark qw(:all);
use Global::IPC::StaticVariable qw/var_create var_destory var_read var_update var_append var_getreset var_length/;

my $id = var_create();

print timestr timeit(1_000_000, sub {
    var_update($id, "hoge");
});
print "\n";

var_destory($id);

__END__
# perl -Mblib benchmark/var_update.t 
 2 wallclock secs ( 0.21 usr +  0.94 sys =  1.15 CPU) @ 869565.22/s (n=1000000)
