prog='dbmerge'
# 17 is because we merge in a binary tree, and it has 1 extra
args='--xargs -n n'
cmd_tail='| dbrowuniq -c'
cmp='diff -c -b '
