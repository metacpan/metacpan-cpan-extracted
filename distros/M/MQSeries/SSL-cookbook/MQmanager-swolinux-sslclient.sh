#!/bin/bash
# This is MQmanager sample config setup file, use it as a quickstart sample
# First you must have IBM WebsphereMQ server installed

# Problems:
# AMQ7064: Log path not valid or inaccessible. -> delete old logpath access

# When finished also remove related entries in /var/mqm/mqs.ini
# They are not removed by the dltmqm command
# use netstat -na | grep portnumber to verify port is open: and should be listening
#$ netstat -na | grep 6666
#tcp        0      0 :::6666    :::*        LISTEN



######################################################################
# This is a very simple sample on a local queuemanager with one queue
# and a channel to connect to
######################################################################
# name of your queue-manager wou will connect to
QM=swolinux;

# name of the queue on the queuemanager
QUEUE=secana.queue;

# where to find the mqsslkeyrepository
MQSSL=/var/mqm/ssl/swolinux

# port to connect to on queuemanager
PORT=6666;

# name of the channel the client connects to
CHANNEL=secana.ssl;
######################################################################

echo "Setting up $QM";

echo "end eventual old $QM:"
endmqm $MQ;

echo "delete eventual old $QM:"
dltmqm $MQ;

echo "create new $QM:"
crtmqm $QM;

echo "start new $QM:"
strmqm $QM;

echo "\
* Sets up a local queue on server
CLEAR QLOCAL('$QUEUE');

DEFINE QLOCAL('$QUEUE') REPLACE +
        DESCR('queue used for secana transactions') +
        PUT(ENABLED) +
        DEFPRTY(0) +
        DEFPSIST(YES) +
        GET(ENABLED) +
        MAXDEPTH(10000) +
*       MAXMSGL(15000) +
        DEFSOPT(SHARED) +
        NOHARDENBO         +
        USAGE(NORMAL) +
        NOTRIGGER;

DIS Q('$QUEUE') ALL;

* We need an listener for incomming messages
STOP LISTENER('listener');
DELETE LISTENER('listener');

DEFINE LISTENER('listener') +
        TRPTYPE(TCP) PORT($PORT) CONTROL(QMGR) +
        DESCR('TCP/IP Listener for this queue-manager') +
        REPLACE;

STOP CHANNEL('$CHANNEL');
* DELETE CHANNEL('$CHANNEL');

* SVRCONN channels are used for clients to connect to
DEFINE CHANNEL('$CHANNEL') +
  CHLTYPE(SVRCONN) TRPTYPE(TCP) +
  MCAUSER('') +
  SSLCAUTH(REQUIRED) +
* SSLPEER('OU=Decision Analytics*') +
  SSLCIPH('NULL_MD5') +
  REPLACE;
" | runmqsc $QM

echo "ALTER QMGR SSLKEYR('$MQSSL')" | runmqsc $QM

echo "\
* display channel
DIS CHANNEL('$CHANNEL') ALL;

* start channel
START CHANNEL('$CHANNEL')

* start listener
START LISTENER('listener')" | runmqsc $QM

