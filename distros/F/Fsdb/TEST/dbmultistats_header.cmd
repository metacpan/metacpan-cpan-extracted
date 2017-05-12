prog='dbmultistats'
args='--header="#fsdb experiment duration" -k experiment duration'
in=TEST/dbmapreduce_header.in
cmp='diff -c -b '
portable=false
subprogs=dbstats
altcmp='dbfilediff --quiet -E --exit '
altcmp_needs_input_flags=true
