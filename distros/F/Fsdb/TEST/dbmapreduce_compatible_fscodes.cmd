prog='dbmapreduce'
args='-k experiment -- dbcolstats --nolog -F S duration'
cmp='diff -c -b '
subprogs=dbcolstats
in=TEST/dbmapreduce_incompatible_fscodes.in
suppress_warnings='5.1[0-2]:Unbalanced string table refcount;5.1[0-2]:Scalars leaked'
