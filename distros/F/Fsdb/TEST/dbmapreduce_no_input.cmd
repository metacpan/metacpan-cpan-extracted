prog='dbmapreduce'
args='-k experiment -C "dbcolstats(qw(--nolog duration))"'
cmp='diff -c -b '
