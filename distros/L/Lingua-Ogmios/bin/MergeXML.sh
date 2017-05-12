#!/bin/bash

# Concatenation of a list of Alvis XML files into on file
# Files are specified on the command line

cat $1 | head -2

cat $@ | grep -v '<?xml version' | grep -v '<documentCollection' | grep -v '</documentCollection'

cat $1 | tail -1

exit;

