#!/bin/bash

#WSDL2PERL="/usr/local/bin/wsdl2perl.pl";
WSDL2PERL=`which wsdl2perl.pl`;

CDIR=`pwd`;

$WSDL2PERL -s file://$CDIR/TestBind.wsdl
