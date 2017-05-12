prog='dbmultistats'
args='-S -S -k experiment duration'
in=TEST/dbmapreduce_grouped_incorrectly.in
cmp='diff -c -b '
portable=false
subprogs=dbstats
altcmp='dbfilediff --quiet -E --exit '
altcmp_needs_input_flags=true
