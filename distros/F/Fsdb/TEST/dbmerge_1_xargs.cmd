prog='dbmerge'
# 1 because there's nothing to actually merge
args='--xargs -n n'
# cmd_tail='| dbrowuniq -c'
cmp='diff -c -b '
