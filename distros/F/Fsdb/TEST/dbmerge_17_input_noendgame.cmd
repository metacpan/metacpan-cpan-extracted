prog='dbmerge'
# 17 is because we merge in a binary tree, and it has 1 extra
args='--noendgame -n -i TEST/dbmerge_1k.in  -i TEST/dbmerge_1k.in  -i TEST/dbmerge_1k.in  -i TEST/dbmerge_1k.in  -i TEST/dbmerge_1k.in  -i TEST/dbmerge_1k.in  -i TEST/dbmerge_1k.in  -i TEST/dbmerge_1k.in  -i TEST/dbmerge_1k.in  -i TEST/dbmerge_1k.in  -i TEST/dbmerge_1k.in  -i TEST/dbmerge_1k.in  -i TEST/dbmerge_1k.in  -i TEST/dbmerge_1k.in  -i TEST/dbmerge_1k.in  -i TEST/dbmerge_1k.in  -i TEST/dbmerge_1k.in n'
cmd_tail='| dbrowuniq -c'
in='/dev/null'
cmp='diff -c -b '
