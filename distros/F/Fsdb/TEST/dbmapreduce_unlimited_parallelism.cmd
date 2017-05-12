prog='dbmapreduce'
args='-S --test-parallelism --prepend-key --parallelism=100 -K -k experiment -- perl TEST/dbmapreduce_limited_parallelism.pl'
in=TEST/dbmapreduce_limited_parallelism.in
cmp='diff -c -b '
altcmp='dbfilediff --quiet -E --exit '
altcmp_needs_input_flags=true
