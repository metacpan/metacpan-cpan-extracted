#!/bin/bash

echo Contents of data/$1.dash:
cat data/$1.dash
echo ----------------------------
perl -Ilib scripts/render.pl -i data/$1.dash -dot data/$1.gv -o html/$1.svg $2 $3 $4 $5
echo ----------------------------
