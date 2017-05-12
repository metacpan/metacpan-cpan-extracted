#!/bin/sh

PREFIX=`date | openssl md5`

egrep -A12 "^AcDbLine.?$" \
    | egrep "^[-]?[0-9]" \
    | split --suffix-length=4 --lines=6 - $PREFIX

find -maxdepth 1 | grep $PREFIX \
    | while read line; do \
        echo 'Units: mm' > "$line.line"; \
        nl $line \
	| sed 's/     [123]./0: /' \
	| sed 's/     [456]./1: /' >> "$line.line"; \
	rm $line \
    ; done


