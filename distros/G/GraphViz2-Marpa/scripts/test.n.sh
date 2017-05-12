#!/bin/bash

FILE=$1

MAX=$2

if [ -z "$MAX" ]
then
	MAX=info
fi

for i in data/$FILE*.gv ;
do
	X=`basename $i .gv`

	scripts/test.1.sh $X $MAX
done
