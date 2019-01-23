#!/bin/bash
set -e
ROOT=/opt/mydan
test -e $ROOT/.lock  && exit 1
tar -zxvf $TMP -C /
mkdir -p $ROOT/tmp && chmod 777 $ROOT/tmp && chmod +t $ROOT/tmp
rsync -av $ROOT/etc/agent/auth.tmp/ $ROOT/etc/agent/auth/
rsync -av $ROOT/dan/bootstrap/exec.tmp/agent $ROOT/dan/bootstrap/exec/agent
$ROOT/dan/bootstrap/bin/bootstrap --install
sed -i "s/.*#myrole/  role: agent #myrole/" $ROOT/dan/.config 

echo OK
