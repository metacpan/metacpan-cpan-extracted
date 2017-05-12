#!/bin/bash
set -e

rm -f MANIFEST
perl Build.PL
./Build
./Build manifest
./Build test
./Build dist
