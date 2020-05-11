#!/bin/sh
#
# $Id$
#

PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
PERL_RL=Gnu
PAGER=less
LC_ALL=en_GB.UTF-8
export PATH PERL_RL PAGER LC_ALL

metabrik $@
