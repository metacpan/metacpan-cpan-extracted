prog='dbfilepivot'
args='--possible-pivots="1 2" -k name -p hw -v score'
in=TEST/dbfilepivot_ex.in
cmp='diff -c -b '
expected_exit_code=fail
altout=true
