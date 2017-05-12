prog='dbjoin'
args='-m merge -t outer --input TEST/dbjoin_outer.in-2 -n cid'
cmp='diff -c -b '
in=TEST/dbjoin_outer.in
# right outer should keep only cid 14

