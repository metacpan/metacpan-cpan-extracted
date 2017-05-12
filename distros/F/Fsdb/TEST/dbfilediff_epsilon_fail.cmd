prog='dbfilediff'
args='-E --quiet --input TEST/dbfilediff_epsilon_fail.in --input TEST/dbfilediff_epsilon_fail.in-2'
in=/dev/null
cmp='diff -c -b '
