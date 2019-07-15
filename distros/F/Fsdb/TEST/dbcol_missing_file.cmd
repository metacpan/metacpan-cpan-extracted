prog='dbcol'
args='--input TEST/nonexistant_file account'
cmp='diff -c -b '
in=/dev/null
expected_exit_code=fail
