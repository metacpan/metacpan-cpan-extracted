prog='dbmapreduce'
args='-M -k experiment -- dbmultistats duration'
cmp='diff -c -b '
in=TEST/dbmapreduce_no_input.in
