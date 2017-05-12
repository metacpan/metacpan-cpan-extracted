#!/bin/bash

if [ -d "lib/MathPerl/Geometry" ]; then
    cd lib/MathPerl/Geometry
elif [ -d "MathPerl/Geometry" ]; then
    cd MathPerl/Geometry
else
    echo "Can't find lib/MathPerl/Geometry or MathPerl/Geometry directories, dying"
    exit
fi

rm PiDigits.h 2> /dev/null
rm PiDigits.cpp 2> /dev/null
rm PiDigits.pmc 2> /dev/null
