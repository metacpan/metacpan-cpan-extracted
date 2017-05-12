prog='dbmapreduce'
args='-k experiment -f TEST/dbmapreduce_external_file.pl -C make_reducer'
cmp='diff -c -b '
in=TEST/dbmapreduce_ex.in
altcmp='dbfilediff --quiet -E --exit '
altcmp_needs_input_flags=true
