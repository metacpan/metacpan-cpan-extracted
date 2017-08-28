#!/usr/bin/env bash

export DEV='DEV'
RSYNC_HPC="rsync -avz ../HPC-Runner-Command gencore@dalma.abudhabi.nyu.edu:/home/gencore/hpcrunner-test/"
RSYNC_BIOSAILS="rsync -avz ../BioSAILs gencore@dalma.abudhabi.nyu.edu:/home/gencore/hpcrunner-test/"
RSYNC_SQL="rsync -avz ../HPC-Runner-Command-Plugin-Logger-Sqlite gencore@dalma.abudhabi.nyu.edu:/home/gencore/hpcrunner-test/"
inotify-hookable \
    --watch-directories /home/jillian/Dropbox/projects/HPC-Runner-Libs/New/BioSAILs/lib \
    --watch-directories lib \
    --watch-directories t \
    --watch-files t/test_class_tests.t \
    --on-modify-command "${RSYNC_HPC}; ${RSYNC_BIOSAILS}; ${RSYNC_SQL}; prove -l -v t/test_class_tests.t"
