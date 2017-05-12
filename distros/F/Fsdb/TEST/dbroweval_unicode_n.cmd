prog='dbroweval'
args='-b "binmode STDOUT, \":utf8\";" -n -f TEST/dbroweval_unicode_n.code'
in=TEST/dbcol_unicode.in
cmp='diff -c -b '
