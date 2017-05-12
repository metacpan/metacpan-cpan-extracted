#!/bin/sh

RPM=false
AUTOCONF=true

VER=`perl get-version.pl`

rm -f Mail-LMLM-"$VER".tar.gz

for OPT do
    if [ "$OPT" == "--rpm" ] ; then
        RPM=true
    elif [ "$OPT" == "--noac" ] ; then
        AUTOCONF=false
    else
        echo "Unknown option \"$OPT\"!"
        exit -1
    fi
done


if $AUTOCONF ; then
    perl Makefile.PL
fi

make dist

if $RPM ; then
    rpm -tb Mail-LMLM-"$VER".tar.gz
fi


