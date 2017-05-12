#! /bin/sh
LO="-interaction=batchmode"
cd examples
  for i in *.pl
  do
    echo Processing $i
    perl $i
  done
cd ..
cd doc-src
  for i in diagram-de diagram-en
  do
    echo Processing $i
    pdflatex $i && pdflatex $LO $i && pdflatex $LO $i && mv $i.pdf ..
  done
cd ..

