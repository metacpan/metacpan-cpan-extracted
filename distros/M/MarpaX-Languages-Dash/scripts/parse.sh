#!/bin/bash

echo Contents of data/$1.dash:
cat data/$1.dash
echo ----------------------------
perl -Ilib scripts/parse.pl -i data/$1.dash $2 $3 $4 $5
echo ----------------------------
