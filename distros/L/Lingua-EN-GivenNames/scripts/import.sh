#!/bin/bash

rm data/derivations.raw data/derivations.csv data/mismatches.log data/parse.log

for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20;
do
	perl -Ilib scripts/extract.derivations.pl -v 1 -s female -p $i
done

for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17;
do
	perl -Ilib scripts/extract.derivations.pl -v 1 -s male -p $i
done

perl -Ilib scripts/parse.derivations.pl -v 1

sort < data/mismatches.log > $$.log
mv $$.log data/mismatches.log

perl -Ilib scripts/drop.tables.pl
perl -Ilib scripts/create.tables.pl
perl -Ilib scripts/import.derivations.pl -v 1
perl -Ilib scripts/export.pl -w data/given.names.html -v 1
