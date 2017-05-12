prog='dbjoin'
args='-m righthash -t inner --input TEST/dbjoin_outer.in-2 -n cid'
cmp='diff -c -b '
in=TEST/dbjoin_outer.in
# inner should keep neither cid 14 nor 13
