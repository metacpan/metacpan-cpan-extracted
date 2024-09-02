#!/bin/sh
perl Build.PL
perl Build install

perl Build dist
perl Build ppmdist
perl Build ppd

