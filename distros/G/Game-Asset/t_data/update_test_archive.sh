#!/bin/bash
ARCHIVE=test1.zip
ARCHIVE_DIR=tmp

CUR_DIR=`pwd`


rm -f ${ARCHIVE}
cd ${ARCHIVE_DIR}
FILE_LIST=`find .  -print | perl -nE 's!^\./?!!; chomp; print "$_ " if /\S/'`
zip ${CUR_DIR}/${ARCHIVE} ${FILE_LIST}
cd ${CUR_DIR}
