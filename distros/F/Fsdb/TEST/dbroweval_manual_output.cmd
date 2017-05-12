prog='dbroweval'
args='-m -b "@out_args = (-cols => [qw(size n)]);" "\$ofref = [ _size, 1 ];"'
in='TEST/dbroweval_ex.in'
cmp='diff -c -b '
