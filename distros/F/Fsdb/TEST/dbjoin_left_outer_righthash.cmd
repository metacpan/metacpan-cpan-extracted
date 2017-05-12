prog='dbjoin'
args='-m righthash -t left --input TEST/dbjoin_outer.in-2 -n cid'
cmp='diff -c -b '
in=TEST/dbjoin_outer.in
# left outer should keep only sid 13

