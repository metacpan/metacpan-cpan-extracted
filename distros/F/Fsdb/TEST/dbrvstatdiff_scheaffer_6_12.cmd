# example 6.12 from Scheaffer and McClave
prog='dbrvstatdiff'
args='mean2 stddev2 n2 mean1 stddev1 n1'
cmp='diff -c -b '
altcmp='dbfilediff --quiet -E  -N test_diff --exit '
altcmp_needs_input_flags=true
