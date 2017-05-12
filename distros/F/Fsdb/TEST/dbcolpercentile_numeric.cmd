prog='dbcolpercentile'
args='test1'
in=TEST/dbcolpercentile_numeric.in
cmp='diff -c -b '
altcmp='dbfilediff --quiet -E --exit '
altcmp_needs_input_flags=true
