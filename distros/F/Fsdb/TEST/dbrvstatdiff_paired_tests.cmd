prog='dbrvstatdiff'
args='-h "=0" mean stddev n copylast_mean copylast_stddev copylast_n'
cmp='diff -c -b '
altcmp='dbfilediff --quiet -E -N test_diff --exit '
altcmp_needs_input_flags=true
