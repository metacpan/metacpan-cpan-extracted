#!/bin/bash
ROOT=MYDanROOT
test -e $ROOT/etc/mydan.lock && exit 1;
tar -zxvf $TMP -C / || exit 1
sed -i "s/.*#myrole/  role: client #myrole/" $ROOT/dan/.config || exit 1

echo OK
