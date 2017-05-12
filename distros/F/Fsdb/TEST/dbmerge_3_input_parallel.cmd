prog='dbmerge'
# 3 to test endgame mode
args='--parallelism=10 -n -i TEST/dbmerge_1k.in  -i TEST/dbmerge_1k.in  -i TEST/dbmerge_1k.in n'
cmd_tail='| dbrowuniq -c'
in='/dev/null'
cmp='diff -c -b '
