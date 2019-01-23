#!/bin/bash
set -e
ROOT=/opt/mydan
test -e $ROOT/.lock && exit 1
tar -zxvf $TMP -C /
mkdir -p $ROOT/tmp && chmod 777 $ROOT/tmp && chmod +t $ROOT/tmp
sed -i "s/.*#myrole/  role: client #myrole/" $ROOT/dan/.config

echo OK
