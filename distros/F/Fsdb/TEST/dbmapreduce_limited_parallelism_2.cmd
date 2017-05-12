prog='dbmapreduce'
args='-S --test-parallelism --prepend-key --parallelism=2 -K -k experiment -- perl TEST/dbmapreduce_limited_parallelism.pl'
cmp='diff -c -b '
altcmp='dbfilediff --quiet -E --exit '
altcmp_needs_input_flags=true
