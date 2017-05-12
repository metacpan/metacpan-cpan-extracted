#!/bin/bash

SRCDIR="/vagrant"
TESTDIR="/home/vagrant/gccjit-test"
VMS="f22-64 deb8-32 deb8-64"

export LC_ALL=C

if [ "$1" = "vagrant-run" ]; then
	set -e
	test -d $SRCDIR
	rm -rf $TESTDIR
	git clone $SRCDIR $TESTDIR
	cd $TESTDIR
	perl Makefile.PL
	make
	make test
else 
	for vm in $VMS; do
		echo "Running tests in $vm"
		vagrant ssh $vm -- "$SRCDIR/tools/test.sh" vagrant-run
	done
fi
