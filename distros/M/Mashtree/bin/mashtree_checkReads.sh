#!/bin/bash

set -e
set -u

READS=$@
if [ -z "$READS" ]; then
  echo "Usage: $0 *.fastq.gz"
  exit 1;
fi

export PATH=$(dirname $0)/ROSS-0.3/scripts:$PATH

friends_ross=$(which friends_ross.pl) || {
  echo;
  echo "ERROR: the ROSS package was not detected in Mashtree/bin/ROSS-*.";
  echo "Usually this is installed by running Mashtree perl Makefile.pl && make";
  exit 1;
}

for i in $READS; do 
  output=$(zcat $i | $friends_ross --verbose 2>&1)
  if [ $? -gt 0 ]; then
    echo -e "ERROR with $i:\n$output\n";
  fi
done

