prog='dbcolstatscores'
args='--tmean 50 --tstddev 10 test1'
cmp='diff -c -b '
portable=false
subprogs=dbstats
altcmp='dbfilediff --quiet -E --exit '
altcmp_needs_input_flags=true
