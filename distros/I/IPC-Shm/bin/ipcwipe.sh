#!/bin/sh

ipcrm -m `ipcs -m | awk '/beef/{print $2}'` 2> /dev/null

for m in `ipcs -m | grep -v dest | awk '/0000/{print $2}'` ; do
	ipcrm -m $m
done

for s in `ipcs -s | awk '/0000/{print $2}'` ; do
	ipcrm -s $s
done
