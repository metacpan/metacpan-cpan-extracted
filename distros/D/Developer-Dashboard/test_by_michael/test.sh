#!/bin/bash
V=$1
cp -v ../Developer-Dashboard-$V.tar.gz DD.tgz \
&& docker compose up -d --build \
&& ./setup.sh
