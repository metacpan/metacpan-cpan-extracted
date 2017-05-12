prog='dbjoin'
args='-m righthash -t outer --input TEST/dbjoin_outer.in-2 -n cid'
cmp='diff -c -b '
in=TEST/dbjoin_outer.in
