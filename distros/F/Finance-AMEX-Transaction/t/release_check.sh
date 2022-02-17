#!/bin/bash

for file in $(find -type f \( -iname \*.pm -or -iname \*.t \) -not -path "./.build/*")
do 
  echo -n \# ... ${file} ...
  perltidy ${file} ; diff -Naur ${file} ${file}.tdy ; test -e ${file}.tdy && rm ${file}.tdy
  perlcritic ${file}
done
