#!/bin/sh

for i in $(find ./lib/EBook/ -name \*.pm | grep -v MobiPerl); do grep ^EBook::MOBI $i; done
