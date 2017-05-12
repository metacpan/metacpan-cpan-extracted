#!/usr/bin/env bash
perl Build.pl
./Build
./Build test
./Build dist
./Build install
