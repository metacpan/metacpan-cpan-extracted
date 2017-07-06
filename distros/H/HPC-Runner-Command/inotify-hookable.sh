#!/usr/bin/env bash

export DEV='DEV'
inotify-hookable \
    --watch-directories lib \
    --watch-directories t \
    --watch-files t/test_class_tests.t \
    --on-modify-command "prove -l -v t/test_class_tests.t"
