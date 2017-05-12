#!/bin/bash -e

# Copyright 2002 Dirk Eddelbuettel <edd@debian.org>, and GPL'ed

# Call e.g. with argument 555750.F to map Deutsche Tekekom into DTEGN.F

for i in $@; do
    echo "$i"
    lynx -dump "http://de.finance.yahoo.com/q?s=$i&d=t" 		| \
	perl -n -e 'print "\t", uc $1,"\n" if (/s=([a-zA-Z\.]*)\&/);' 	| \
	sort | uniq
done
