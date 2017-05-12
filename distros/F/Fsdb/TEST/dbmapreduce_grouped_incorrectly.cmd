prog='dbmapreduce'
args='-S -S -k experiment dbcolstats duration'
cmp='diff -c -b '
subprogs=dbcolstats
suppress_warnings='5.1[0-2]:Unbalanced string table refcount;5.1[0-2]:Scalars leaked'
altcmp='dbfilediff --quiet -E --exit '
altcmp_needs_input_flags=true
