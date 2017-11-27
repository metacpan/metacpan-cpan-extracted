prog='dbmapreduce'
args='-k experiment -C "dbcolstats(qw(--nolog --output-on-no-input duration))"'
cmp='diff -c -b '
