#!/bin/bash

for i in xt/author/data/u*.gv ;
do
	X=`basename $i .gv`

	perl -Ilib scripts/g2m.pl -input_file $i

	if [ "$?" -eq "0" ]
	then
		echo OK. Parsed gv: $i.

		#echo Render. In: $i. Out: /tmp/$X.gv

		perl -Ilib scripts/g2m.pl -input_file $i -output_file /tmp/$X.gv

		dot -Tsvg $i > /tmp/$X.old.svg

		#echo Dot in: $i. Out: /tmp/$X.old.svg

		dot -Tsvg /tmp/$X.gv > xt/author/html/$X.svg

		#echo Dot out: /tmp/$X.gv. Out: /tmp/$X.new.svg

		diff /tmp/$X.old.svg xt/author/html/$X.svg

		if [ "$?" -eq "0" ]
		then
			echo OK. Rendered and diffed svgs: $i.
		else
			echo Fail. Rendered and diffed svgs: $i.
		fi
	else
		echo Fail. Parsed $i.
	fi

	echo ------------
done
