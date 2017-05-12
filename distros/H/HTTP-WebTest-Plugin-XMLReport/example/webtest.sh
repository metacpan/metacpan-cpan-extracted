#!/bin/sh
#
# script to demonstrate some possibilities of XMLReport plugin
#
# Prerequisites:
XSLT=xsltproc          # part of Gnome/LibXML
WEBTEST="./webtest"    # perl wrapper
SENDMAIL="/bin/true"   # replace by Sendmail, e.g.
# SENDMAIL="/usr/sbin/sendmail -t"

$WEBTEST --config="testdefs.xml" >out1.xml
if [ ! -s out1.xml ]
then
    echo "Empty test output 'out1.xml', further processing stopped."
    exit 1
fi
# generate testscript for failed tests only
$XSLT --param testdoc "'../testdefs.xml'" transform/extract-failed.xsl out1.xml >failed1.xml
# wait before retrying failed tests
sleep 5
# 2nd iteration: run only tests that failed in 1st round
$WEBTEST --config="failed1.xml" >out2.xml
# merge results into enhanced test report
$XSLT --param merge "'../out2.xml'" --param testdoc "'../testdefs.xml'" \
        transform/merge-results.xsl out1.xml >result.xml
# generate sidebar HTML
$XSLT transform/sidebar.xsl result.xml >"sidebar.html"
# generate main report HTML
$XSLT transform/content.xsl result.xml >"content.html"
# generate email; will be empty if all tests passed
$XSLT --param testdoc "'../testdefs.xml'" transform/email.xsl out2.xml >email.txt
if [ -s email.txt ]; then $SENDMAIL <email.txt ; fi

