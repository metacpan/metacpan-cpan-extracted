#!/bin/sh

perl map.pl < input/terms.txt | sort | perl reduce.pl
