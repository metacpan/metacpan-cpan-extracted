prog='csv_to_db'
args='-F t'
cmp='diff -c -b '
# suppress this test on systems that lack this package
requires='Text::CSV_XS'
in=TEST/csv_to_db.in
