#!/bin/sh
set -e

CURLVER=8.15.0
[ -f curl-$CURLVER.tar.gz ] || curl --output curl-$CURLVER.tar.gz https://curl.se/download/curl-$CURLVER.tar.gz
tar -xf curl-$CURLVER.tar.gz
mv curl-$CURLVER curl-src

cd curl-src/docs/libcurl
perl symbols.pl > ../../../libcurl-symbols.h
cd ../../..

perl sync-constants.pl
rm -rf curl-src
