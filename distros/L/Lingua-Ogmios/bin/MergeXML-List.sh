#!/bin/bash

# Concatenation of a list of Alvis XML files into on file
# Files are specified on in a file given as first argument

cat `cat $1 |head -1` | head -2

cat `cat $1` |sed -e 's/<\/documentCollection/\n<\/documentCollection/g' | grep -v '<?xml version' | grep -v '<documentCollection' | grep -v '</documentCollection'

cat `cat $1 |head -1` | sed -e 's/<\/documentCollection/\n<\/documentCollection/g' | tail -1

exit;

