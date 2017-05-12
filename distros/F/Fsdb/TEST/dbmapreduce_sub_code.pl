# example external reducer with a CODE ref

use Fsdb::Filter::dbpipeline qw(:all);

dbmapreduce('--autorun', -k => 'experiment', -C => sub { dbcolstats(qw(--nolog duration)); });

