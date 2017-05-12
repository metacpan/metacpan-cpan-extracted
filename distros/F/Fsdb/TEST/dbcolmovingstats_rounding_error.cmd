prog='dbcolmovingstats'
# The following input SOMETIMES goes negative on the sqrt around line 3694
# (the run of 0.8244 values).   We now catch that that in dbcolmovingstats.
args='-w 20 a_short'
cmp='diff -c -b '
altcmp='dbfilediff --quiet -E --exit '
altcmp_needs_input_flags=true
