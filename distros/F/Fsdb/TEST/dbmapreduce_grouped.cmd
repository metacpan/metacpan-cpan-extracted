prog='dbmapreduce'
args='-S -k experiment dbcolstats duration'
in=TEST/dbmapreduce_ex.in
cmp='diff -c -b '
subprogs=dbcolstats
suppress_warnings='5.1[0-2]:Unbalanced string table refcount;5.1[0-2]:Scalars leaked'
altcmp='dbfilediff --quiet -E --exit '
altcmp_needs_input_flags=true
