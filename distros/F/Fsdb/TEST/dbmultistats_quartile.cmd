prog='dbmultistats'
args='-q 4 -k experiment duration'
cmp='diff -c -b '
# suppress_warnings='5.10:Attempt to free unreferenced scalar'
altcmp='dbfilediff --quiet -E --exit '
altcmp_needs_input_flags=true
