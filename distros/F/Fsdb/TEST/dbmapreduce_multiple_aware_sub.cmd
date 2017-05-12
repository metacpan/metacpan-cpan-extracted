prog='dbmapreduce'
args='-S -S -M -k experiment -f TEST/dbmapreduce_multiple_aware_sub.pl -C simple_reducer'
cmp='diff -c -b '
in=TEST/dbmapreduce_ex.in

