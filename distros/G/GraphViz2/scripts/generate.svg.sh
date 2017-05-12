#!/bin/bash

DIR=/tmp

if [ -z $DBI_DSN ]; then
	echo Warning: DBI_DSN not set for scripts/dbi.schema.pl.
fi

perl -Ilib scripts/Heawood.pl           svg > $DIR/Heawood.log
perl -Ilib scripts/anonymous.pl         svg > $DIR/anonymous.log
perl -Ilib scripts/circo.pl             svg > $DIR/circo.log
perl -Ilib scripts/cluster.pl           svg > $DIR/cluster.log
perl -Ilib scripts/dbi.schema.pl        svg > $DIR/dbi.schema.log
perl -Ilib scripts/dependency.pl        svg > $DIR/dependency.log
perl -Ilib scripts/html.labels.1.pl     svg > $DIR/html.labels.1.log
perl -Ilib scripts/html.labels.2.pl     svg > $DIR/html.labels.2.log
perl -Ilib scripts/jointed.edges.pl     svg > $DIR/jointed.edges.log
perl -Ilib scripts/macro.1.pl           svg > $DIR/macro.1.log
perl -Ilib scripts/macro.2.pl           svg > $DIR/macro.2.log
perl -Ilib scripts/macro.3.pl           svg > $DIR/macro.3.log
perl -Ilib scripts/macro.4.pl           svg > $DIR/macro.4.log
perl -Ilib scripts/macro.5.pl           svg > $DIR/macro.5.log
perl -Ilib scripts/parse.data.pl        svg > $DIR/parse.data.log
perl -Ilib scripts/parse.html.pl        svg > $DIR/parse.html.log
perl -Ilib scripts/parse.isa.pl         svg > $DIR/parse.isa.log
perl -Ilib scripts/parse.recdescent.pl  svg > $DIR/parse.recdescent.log
perl -Ilib scripts/parse.regexp.pl      svg > $DIR/parse.regexp.log
perl -Ilib scripts/parse.stt.pl         svg > $DIR/parse.stt.log
perl -Ilib scripts/parse.xml.bare.pl    svg > $DIR/parse.xml.bare.log
perl -Ilib scripts/parse.xml.pp.pl      svg > $DIR/parse.xml.pp.log
perl -Ilib scripts/parse.yacc.pl        svg > $DIR/parse.yacc.log
perl -Ilib scripts/parse.yapp.pl        svg > $DIR/parse.yapp.log
perl -Ilib scripts/plaintext.pl         svg > $DIR/plaintext.log
perl -Ilib scripts/quote.pl             svg > $DIR/quote.log
perl -Ilib scripts/rank.sub.graph.1.pl  svg > $DIR/rank.sub.graph.1.log
perl -Ilib scripts/rank.sub.graph.2.pl  svg > $DIR/rank.sub.graph.2.log
perl -Ilib scripts/rank.sub.graph.3.pl  svg > $DIR/rank.sub.graph.3.log
perl -Ilib scripts/rank.sub.graph.4.pl  svg > $DIR/rank.sub.graph.4.log
perl -Ilib scripts/record.1.pl          svg > $DIR/record.1.log
perl -Ilib scripts/record.2.pl          svg > $DIR/record.2.log
perl -Ilib scripts/record.3.pl          svg > $DIR/record.3.log
perl -Ilib scripts/record.4.pl          svg > $DIR/record.4.log
perl -Ilib scripts/sub.graph.pl         svg > $DIR/sub.graph.log
perl -Ilib scripts/sub.graph.frames.pl  svg > $DIR/sub.graph.frames.log
perl -Ilib scripts/sub.sub.graph.pl     svg > $DIR/sub.sub.graph.log
perl -Ilib scripts/trivial.pl           svg > $DIR/trivial.log
perl -Ilib scripts/unnamed.sub.graph.pl svg > $DIR/unnamed.sub.graph.log
perl -Ilib scripts/utf8.1.pl            svg > $DIR/utf8.1.log
perl -Ilib scripts/utf8.2.pl            svg > $DIR/utf8.2.log

perl -Ilib scripts/generate.demo.pl svg

# $DR is my web server's doc root.

PM=Perl-modules/html/graphviz2

cp html/* $DR/$PM
cp html/* ~/savage.net.au/$PM

echo Check the version number in the demo index
