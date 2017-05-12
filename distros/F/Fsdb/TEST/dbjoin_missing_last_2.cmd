prog='dbjoin'
args='-S -e 0 -a --input TEST/dbjoin_missing_last_2.in-2 --input - low'
in=TEST/dbjoin_missing_last_1.in
cmp='diff -c -b '
