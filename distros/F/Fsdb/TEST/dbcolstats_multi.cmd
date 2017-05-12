prog='dbcolstats'
args='-k experiment duration'
in=TEST/dbmapreduce_ex.in
cmp='diff -c '
altcmp='dbfilediff --quiet -E --exit '
altcmp_needs_input_flags=true
