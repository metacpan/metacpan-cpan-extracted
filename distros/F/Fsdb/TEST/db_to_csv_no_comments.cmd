prog='db_to_csv'
args='-C'
in=TEST/db_to_csv.in
cmp='diff -c -b '
requires='Text::CSV_XS'
