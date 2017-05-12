prog='dbmapreduce'
args='--no-prepend-key -k experiment -C "dbcolstats(qw(--nolog duration))"'
cmp='diff -c -b '
predecessor=dbmapreduce_sub.cmd
in=TEST/dbmapreduce_ex.in
altcmp='dbfilediff --quiet -E --exit '
altcmp_needs_input_flags=true
