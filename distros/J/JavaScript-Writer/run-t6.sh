#!/bin/sh

for i in t6/*.t
do
    echo Running $i
    pugs -Ilib6 $i
done

