#!/bin/sh

if [ $# != 1 ] ; then
   echo "Usage : $0 <extension>"
   echo "   ou extension est pdf ou eps"
   echo "   Exemple : $0 pdf"
   exit 1
fi

if [ "$1" == "eps" ] ; then
    transfig -L $1  *.fig
fi
if [ "$1" == "pdf" ] ; then
    transfig -L $1 -M Makefile.in *.fig
    sed "s/.tex/.$1/g;" Makefile.in > Makefile
fi
make

