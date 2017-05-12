#!/bin/sh
#
# $Id: metabrik.sh,v 5e03901df915 2015/10/17 10:29:48 gomor $
#

PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
PERL_RL=Gnu
PAGER=less
LC_ALL=en_GB.UTF-8
export PATH PERL_RL PAGER LC_ALL

metabrik $@
