#!/bin/bash
ARCHIVE=test2.zip
ARCHIVE_DIR=tmp2

CUR_DIR=`pwd`


rm -f ${ARCHIVE}
cd ${ARCHIVE_DIR}
FILE_LIST=`find .  -print | perl -nE 's!^\./?!!; chomp; print "$_ " if /\S/'`
zip ${CUR_DIR}/${ARCHIVE} ${FILE_LIST}
cd ${CUR_DIR}
