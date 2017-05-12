prog='dbroweval'
args='-n -m -b "@out_args = (-cols => [qw(n)]); my \$count = 0;" -e "\$ofref = [ \$count ];" "\$count++;"'
in='TEST/dbroweval_ex.in'
cmp='diff -c -b '
