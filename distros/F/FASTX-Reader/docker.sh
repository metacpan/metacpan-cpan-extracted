#!/bin/bash
docker run --rm -v "$PWD":/tmp  perldocker/perl-tester bash ./docker.sh "$@"
