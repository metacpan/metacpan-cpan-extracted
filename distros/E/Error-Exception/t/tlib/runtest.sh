#!/bin/sh

if [ $# -eq 2 ]
then
    debug="$1"
    target="$2"
else
    target="$1"
fi

testrunner=`perl findTestRunner.pl`

perl $debug -I ../../lib $testrunner $target
