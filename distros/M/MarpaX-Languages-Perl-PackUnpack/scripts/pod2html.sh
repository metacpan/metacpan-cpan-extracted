#!/bin/bash

FILE=Perl-modules/html/MarpaX/Languages/Perl/PackUnpack.html

pod2html.pl -i lib/MarpaX/Languages/Perl/PackUnpack.pm -o $DR/$FILE

cp $DR/$FILE ~/savage.net.au/$FILE
