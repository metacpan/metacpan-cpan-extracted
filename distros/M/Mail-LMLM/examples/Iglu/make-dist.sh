#!/bin/sh

VER=`cat ver.txt`
SUBDIR=mailing-lists

if [ ! -e $SUBDIR ] ; then
    mkdir $SUBDIR ;
fi
rm -f $SUBDIR/*
NEWDIR=Shlomif-MailLL-$VER
mkdir ../$NEWDIR
cp -r $(ls | grep -v '^html\.tar\.gz$') ../$NEWDIR/
(cd .. && tar -czvf $NEWDIR.tar.gz $NEWDIR/)
mv ../$NEWDIR.tar.gz $SUBDIR/
rm -fr ../$NEWDIR
perl test.pl
chmod 644 $SUBDIR/*
tar -czvf html.tar.gz $SUBDIR/

