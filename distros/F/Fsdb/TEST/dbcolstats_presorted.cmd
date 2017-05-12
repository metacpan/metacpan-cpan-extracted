prog='dbcolstats'
args='-S -m -q 4 midterm'
cmp='diff -c '
portable=false
subprogs=dbsort
altcmp='dbfilediff --quiet -E --exit '
altcmp_needs_input_flags=true
