#!/bin/sh
#nohup horris run --configfile misc/sample.conf 1> /dev/null 2>&1 &
PERL_HORRIS_DEBUG=1 script/horris run --configfile misc/sample.conf
