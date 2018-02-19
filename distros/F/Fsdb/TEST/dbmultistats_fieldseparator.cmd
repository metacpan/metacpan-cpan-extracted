prog='dbmultistats'
args='-F t -k experiment duration'
in=TEST/dbmapreduce_ex.in
cmp='diff -c -b '
portable=false
subprogs=dbstats
altcmp='dbfilediff --quiet -E --exit '
altcmp_needs_input_flags=true
