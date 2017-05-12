#!/usr/bin/env bash

set -e

exit 0

if [[ $TRAVIS_OS_NAME = "linux" ]]
then
   docker pull quay.io/nyuad_cgsb/hpc-slurm
else
   exit 0
fi
