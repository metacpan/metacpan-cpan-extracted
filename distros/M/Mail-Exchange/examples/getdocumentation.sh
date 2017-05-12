#!/bin/bash

# Not actually an example, but a shell script to fetch the MS master property
# list and convert it to Perl Modules.

mkdir tagdefs
wget -q -O ms-oxprops-structures.html 'http://msdn.microsoft.com/en-us/library/ee179447(v=exchg.80).aspx'
grep '<a href="/en-us/library/' ms-oxprops-structures.html |
cut -d '"' -f2,4 |
tr ' ' '_' |
tr '"' ' '|
while read url name
do
	echo $name
	if test ! -f  tagdefs/$name.html; then
		wget -q -O tagdefs/$name.html http://msdn.microsoft.com$url
	fi
done

perl makepropertyhashes.pl
