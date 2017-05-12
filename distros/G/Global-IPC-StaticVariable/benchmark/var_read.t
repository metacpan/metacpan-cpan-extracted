use strict;
use warnings;

use Benchmark qw(:all);
use Global::IPC::StaticVariable qw/var_create var_destory var_read var_update var_append var_getreset var_length/;

my $id = var_create();
var_update($id, 'hoge');

print timestr timeit(1_000_000, sub {
    var_read($id);
});
print "\n";

var_destory($id);

__END__
# perl -Mblib benchmark/var_read.t 
 0 wallclock secs ( 0.15 usr +  1.01 sys =  1.16 CPU) @ 862068.97/s (n=1000000)
