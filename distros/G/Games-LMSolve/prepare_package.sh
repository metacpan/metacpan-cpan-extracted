#!/bin/sh

RPM=false
AUTOCONF=true

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
    rpm -tb Games-LMSolve-`perl get-version.pl`.tar.gz
fi


