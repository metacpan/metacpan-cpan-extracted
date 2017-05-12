prog='dbmerge'
# 5 inputs stresses endgame mode
args='--endgame --parallelism=14 -n -i TEST/dbmerge_1k.in  -i TEST/dbmerge_1k.in -i TEST/dbmerge_1k.in -i TEST/dbmerge_1k.in -i TEST/dbmerge_1k.in n'
cmd_tail='| dbrowuniq -c'
in='/dev/null'
cmp='diff -c -b '
