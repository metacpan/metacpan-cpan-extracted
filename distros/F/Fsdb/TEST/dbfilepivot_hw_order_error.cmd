prog='dbfilepivot'
args='-S -k name -p hw -v score'
cmp='diff -c -b '
in=TEST/dbfilepivot_hw_order.in
expected_exit_code=fail
