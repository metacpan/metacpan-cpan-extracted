#!/bin/sh
### BEGIN INIT INFO
# Provides:          jlogger
# Required-Start:    $remote_fs $network
# Required-Stop:     $remote_fs $network
# Should-Start:      fam
# Should-Stop:       fam
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Start the JLogger
### END INIT INFO

PATH=/sbin:/bin:/usr/sbin:/usr/bin
DAEMON=/usr/local/bin/jlogger
NAME=jlogger
DESC=JLogger
PIDFILE=/var/run/$NAME.pid
SCRIPTNAME=/etc/init.d/$NAME

DAEMON_OPTS=""

test -x $DAEMON || exit 0

# set -e

. /lib/lsb/init-functions

PID=$(cat $PIDFILE 2>/dev/null || echo -1)

case "$1" in
    start)
        log_daemon_msg "Starting $DESC" $NAME
	if [ -f "$PIDFILE" -a $PID = `pidof -s jlogger || echo 0` ]
	then
	    echo -e "\nAlready running"
            log_end_msg 1
	    exit 0
        fi
        if ! start-stop-daemon --start --oknodo --quiet --background --make-pidfile \
            --pidfile $PIDFILE --exec $DAEMON -- $DAEMON_OPTS
        then
            log_end_msg 1
        else
            log_end_msg 0
        fi
        ;;
    stop)
        log_daemon_msg "Stopping $DESC" $NAME
        if start-stop-daemon --stop --retry 30 --quiet \
            --pidfile $PIDFILE
        then
            rm -f $PIDFILE
            log_end_msg 0
        else
            log_end_msg 1
        fi
        ;;
    restart)
        $0 stop
        $0 start
        ;;
    status)
        status_of_proc -p "$PIDFILE" "perl" jlogger && exit 0 || exit $?
        ;;
    *)
        echo "Usage: $SCRIPTNAME {start|stop|restart|status}" >&2
        exit 1
        ;;
esac

exit 0

