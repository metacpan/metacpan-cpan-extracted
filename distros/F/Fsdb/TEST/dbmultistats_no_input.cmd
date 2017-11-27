prog='dbmultistats'
args='-k experiment duration'
in=TEST/dbmultistats_no_input.in
cmp='diff -c -b '
portable=false
subprogs=dbstats
altcmp='dbfilediff --quiet -E --exit '
altcmp_needs_input_flags=true
