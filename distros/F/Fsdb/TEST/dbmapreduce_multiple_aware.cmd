prog='dbmapreduce'
args='-M -k experiment dbmultistats duration'
predecessor=dbmapreduce_sub_simple.cmd
cmp='diff -c -b '
in=TEST/dbmapreduce_ex.in
altcmp='dbfilediff --quiet -E --exit '
altcmp_needs_input_flags=true
suppress_warnings='5.1[0-2]:Unbalanced string table refcount;5.1[0-2]:Scalars leaked'

