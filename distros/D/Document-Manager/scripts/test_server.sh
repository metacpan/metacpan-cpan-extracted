#!/bin/bash

# This is a simple script to exercise the server and make sure 
# file upload/download works properly.

if [ ! -d /var/dms ]; then
    echo "Directory /var/dms does not exist."
    exit -1
fi

# Delete the /var/dms directory so we're sure to start numbering from 1

rm -rf /tmp/sent /tmp/received /tmp/serverlog /var/dms/*
mkdir /tmp/sent /tmp/received

# Reset the dms
dmsd &> /tmp/serverlog &

########################################################################
# CREATE FILES                                                         #
########################################################################
# Create file 1
touch /tmp/sent/zero

# Create file 2
echo "Hello world"    > /tmp/sent/text.txt

# Create file 3
echo "Compressed Foo" > /tmp/sent/binary.txt
gzip /tmp/sent/binary.txt

# Create file 4
echo "Tarball Bar"    > /tmp/sent/tarball.txt
tar czf /tmp/sent/tarball.tar.gz /tmp/sent/tarball.txt

# Upload the 4 files to the server


########################################################################
# SEND FILES                                                           #
########################################################################

submit_clipart /tmp/sent/zero

submit_clipart /tmp/sent/text.txt

submit_clipart /tmp/sent/binary.txt.gz

submit_clipart /tmp/sent/tarball.tar.gz

########################################################################
# RETRIEVE FILES                                                       #
########################################################################

# TODO:  Download the files to received/
get_clipart 001

get_clipart 002

get_clipart 003

get_clipart 004

########################################################################
# VERIFY FILES                                                         #
########################################################################

cmp /tmp/sent/zero /tmp/received/zero
if [ $? == 0 ]; then
    echo "PASS:  zero"
else
    echo "FAIL:  zero"
fi

cmp /tmp/sent/text.txt /tmp/received/text.txt
if [ $? == 0 ]; then
    echo "PASS:  text.txt"
else
    echo "FAIL:  text.txt"
fi

zcmp /tmp/sent/binary.txt.gz /tmp/received/binary.txt.gz
if [ $? == 0 ]; then
    echo "PASS:  binary.txt.gz"
else
    echo "FAIL:  binary.txt.gz"
fi

zcmp /tmp/sent/tarball.tar.gz /tmp/received/tarball.tar.gz
if [ $? == 0 ]; then
    echo "PASS:  tarball.tar.gz"
else
    echo "FAIL:  tarball.tar.gz"
fi

