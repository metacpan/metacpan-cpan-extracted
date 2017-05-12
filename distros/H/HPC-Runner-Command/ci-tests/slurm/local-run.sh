#!/usr/bin/env bash

set -euo pipefail
#This is only for running against a local docker image. All tests will eventually run through travis
echo "Running local tests"
export HPC_SQLITE_BRANCH="develop"

#Run whole protocol
#docker run -h docker.example.com -p 10022:22 \
#    -e HPC_SQLITE_BRANCH \
#    -c 2 \
#    -i -t -v `pwd`:/hpc-runner-command:Z \
#    --entrypoint /hpc-runner-command/ci-tests/slurm/run-slurm-tests.sh \
#    jerowe/nyuad-cgsb-slurm

#Run with /bin/bash
docker run -h docker.example.com -p 10022:22 \
    -e HPC_SQLITE_BRANCH \
    -i -t -v `pwd`:/hpc-runner-command:Z \
    --entrypoint /bin/bash \
    quay.io/nyuad_cgsb/hpc-slurm
