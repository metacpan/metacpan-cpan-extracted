prog='dbcolstats'
args='-F t absdiff'
cmp='diff -c '
in=TEST/dbcolstats_ex.in
altcmp='dbfilediff --quiet -E --exit '
altcmp_needs_input_flags=true
