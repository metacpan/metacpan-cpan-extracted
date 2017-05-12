prog='dbcolmovingstats'
args='-w 4 -m -a count'
cmp='diff -c -b '
in=TEST/dbcolmovingstats_nonnumeric_no.in
altcmp='dbfilediff --quiet -E --exit '
altcmp_needs_input_flags=true
