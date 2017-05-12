#!/bin/bash

COMMAND=$1

if [ "$COMMAND" == "" ]; then
	echo Parameters: String containing command
else
	MAX=$2;

	if [ "$MAX" == "" ]; then
		MAX='info'
	fi

	perl -Ilib scripts/process.pl -c "$COMMAND" -max $MAX
fi
