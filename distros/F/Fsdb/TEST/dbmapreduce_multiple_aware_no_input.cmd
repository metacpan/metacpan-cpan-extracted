prog='dbmapreduce'
args='-M -k experiment -- dbmultistats --output-on-no-input duration'
subprogs=dbmultistats
cmp='diff -c -b '
in=TEST/dbmapreduce_no_input.in
