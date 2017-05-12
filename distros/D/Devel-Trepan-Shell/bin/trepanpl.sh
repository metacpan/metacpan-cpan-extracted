#!/bin/bash
set -x
exec trepan.pl --cmddir $(dirname ${BASH_SOURCE})/../lib/Devel/Trepan/CmdProcessor/Command $*
