#!/bin/bash
ROOT=MYDanROOT
test -e $ROOT/etc/mydan.lock && exit 1;
tar -zxvf $TMP -C / || exit 1
rsync -av $ROOT/etc/agent/auth.tmp/ $ROOT/etc/agent/auth/ || exit
rsync -av $ROOT/dan/bootstrap/exec.tmp/agent $ROOT/dan/bootstrap/exec/agent || exit
$ROOT/dan/bootstrap/bin/bootstrap --install || exit 1
sed -i "s/.*#myrole/  role: agent #myrole/" $ROOT/dan/.config || exit 1

echo OK
