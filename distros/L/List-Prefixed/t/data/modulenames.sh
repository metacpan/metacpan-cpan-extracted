#!/bin/bash
set -e
set -o pipefail

# This directory
cwd=$(dirname $0) 

# Create test data for ../t/List-Prefixed_large.t

# Get valid Perl module names (extract those followed by a numeric version number and a .tar.gz')
wget -O- https://cpan.metacpan.org/modules/02packages.details.txt | \
	grep -E '^[A-Z][A-Za-z0-9]*(::[A-Za-z0-9]+)*\s+[0-9]+\.[0-9]+.+\.tar\.gz$' | \
	cut -d' ' -f1 | 
	sort -u |
	gzip -9 -c - >$cwd/modulenames.gz

# Grep the names starting with 'List::'
cat $cwd/modulenames.gz | gunzip -c - | grep -E '^List::' | gzip -9 -c - >$cwd/modulenames_List.gz

