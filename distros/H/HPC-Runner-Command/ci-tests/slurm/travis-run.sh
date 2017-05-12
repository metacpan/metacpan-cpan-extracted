#!/bin/bash

set -euo pipefail


export HPC_SQLITE_BRANCH="develop"

if [[ $TRAVIS_OS_NAME = "linux" ]]
then
    #Use docker container to run tests

    docker run -h docker.example.com -p 10022:22 \
        -e TRAVIS_PULL_REQUEST -e TRAVIS_BRANCH \
        -e HPC_SQLITE_BRANCH \
        -i -t -v `pwd`:/hpc-runner-command:Z \
        --entrypoint /hpc-runner-command/ci-tests/slurm/run-slurm-tests.sh \
	quay.io/nyuad_cgsb/hpc-slurm

else
    exit 0
fi
