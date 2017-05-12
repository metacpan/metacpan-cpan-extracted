#!/bin/sh

test -f ../MANIFEST || exec echo "must be started in po"

make update-po

