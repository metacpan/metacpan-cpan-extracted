#!/bin/sh

uncrustify="uncrustify -c .uncrustify.cfg --replace --no-backup"

$uncrustify ./lib/MaxMind/DB/Reader/XS.xs
