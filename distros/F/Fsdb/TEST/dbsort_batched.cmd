prog='dbsort'
# like dbsort_reversed, but with arguments batched as -rn not -r -n
args='-rn test1'
in=TEST/dbsort_numerically.in
cmp='diff -c -b '
