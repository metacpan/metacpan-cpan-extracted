#!/bin/sh
# $Id: restart.sh,v 1.3 2004/03/25 18:59:15 tvierling Exp $

cd $(dirname $0)
kill $(cat milter.pid)
sleep 1

sh -c '
	export PMILTER_DISPATCHER=prefork
	echo $$ >milter.pid
	exec nice -n +4 ./milter.pl >milter.log 2>&1
' &
