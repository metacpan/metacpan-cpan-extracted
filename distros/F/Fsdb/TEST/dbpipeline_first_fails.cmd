prog='perl'
args='TEST/dbpipeline_first_fails.pl'
# will pass with next line
# in='TEST/dbpipeline_flakey.in'
cmp='diff -c -b '
expected_exit_code=fail
altout=true
altcmp='dbfilediff --quiet -E --exit '
