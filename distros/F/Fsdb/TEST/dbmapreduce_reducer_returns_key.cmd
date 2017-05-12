prog='dbmapreduce'
args='--no-prepend-key -k experiment -C "dbrow(\"--nolog\", \"_experiment eq 'ufs_mab_sys'\")"'
cmp='diff -c -b '
in=TEST/dbmapreduce_ex.in
