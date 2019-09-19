prog='dbmerge'
args='--header="#fsdb c_id c_name" --input - --input TEST/dbmerge_ex_b.in c_name'
in=TEST/dbmerge_ex.in
cmp='diff -c -b '
