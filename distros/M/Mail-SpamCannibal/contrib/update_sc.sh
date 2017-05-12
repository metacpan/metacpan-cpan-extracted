#!/bin/sh
#
# update_sc.sh
# update spamcannibal zone file
# version 1.09, 10-19-06, michael@spamcannibal.org
#

###### pid file locations ######
PIDRBLDNS="/var/run/rbldnsd.pid"
PIDNAMED="/var/run/named.pid"

###### rsync server and files ######
ROOT="rsync.spamcannibal.org::zonefiles/"
CMB="bl.spamcannibal.org.in.cmb.rbl"
IP4SET="bl.spamcannibal.org.in.ip4set.rbl"
BIND="bl.spamcannibal.org.in.gz"

###### script ######

usage () {
  echo $1
  echo "     for rsync data retrieval"
  echo "usage:  $0 /zonefile/path/targetname bind|ip4set|combined"
  echo "i.e.    $0 /etc/named/master/somedomain.com bind"
  echo "        $0 /var/lib/rbldns/some.ip4set.set.rbl ip4set"
  echo "        $0 /var/lib/rbldns/some.combined.set.rbl combined"
  echo ""
  echo "     for HUPing the nameserver daemon"
  echo "        $0 HUP named | rbldnsd"
  echo ""
  echo "     for bind, we recommend adding \"rndc flush 'zonename'\""
  echo "               to your cron script as well"
  echo ""
  exit -1
}

if [ $# -ne 2 ] || ([ "bind" != "$2" ] && [ "ip4set" != "$2" ] && [ "combined" != "$2" ] && [ "named" != "$2" ] && [ "rbldnsd" != "$2" ]); then
  usage "bad command format"
fi

function pathof {
  if [ -x /bin/$1 ]; then
    echo /bin/$1
  elif [ -x /usr/sbin/$1 ]; then
    echo /usr/sbin/$1
  elif [ -x /sbin/$1 ]; then
    echo /sbin/$1
  elif [ -x /usr/bin/$1 ]; then
    echo /usr/bin/$1
  elif [ "$1" = "rndc" ]; then
# sigh, rndc is not here, quietly fail
    echo ""
  else
    ERROR="ERROR: could not find path for '$1'"
  fi
}

ERROR=""
CP=`pathof cp`
MV=`pathof mv`
PS=`pathof ps`
WC=`pathof wc`
CAT=`pathof cat`
CUT=`pathof cut`
GZIP=`pathof gzip`
GREP=`pathof grep`
# kill is part of the shell
KILL=kill
RSYNC="`pathof rsync` --stats -ut"
TAIL=`pathof tail`

if [ "$ERROR" != "" ]; then
  echo $ERROR
  exit -1
fi

if [ "HUP" != "$1" ]; then
  TARGET=${1##*/}
  DIR=${1%${TARGET}}

  if [ ! -d $DIR ]; then
    usage "bad directory: $DIR"
  elif [ $TARGET = "" ]; then
    usage "missing target name"
  fi


  if [ "$2" = "bind" ]; then
    FILE=$BIND
    GZ=".gz"
  else
# add zip component for unzipped file
    RSYNC=${RSYNC}z
    GZ=""
    if [ "$2" = "ip4set" ]; then
      FILE=$IP4SET
    else
      FILE=$CMB
    fi
  fi

  RESPONSE=`{
    $RSYNC ${ROOT}${FILE} ${DIR}rsync.${TARGET}${GZ} | $GREP -i literal | $CUT -d' ' -f3
}`

  if [ "$RESPONSE" = "" ] || [ "$RESPONSE" = "0" ]; then
    exit 0
  fi

  if [ "$2" = "bind" ]; then
    $CP ${DIR}rsync.${TARGET}${GZ} ${DIR}tmp.${TARGET}${GZ}
    $GZIP -d ${DIR}tmp.${TARGET}${GZ}
  else
    $CP ${DIR}rsync.${TARGET} ${DIR}tmp.${TARGET}
  fi
# atomic move
  $MV ${DIR}tmp.${TARGET} ${DIR}${TARGET}
  exit 0

#########################################
else	# is a HUP command
#########################################

  if [ "named" != "$2" ] && [ "rbldnsd" != "$2" ]; then
    usage "bad command format"
  fi

# get the first PID of job name in $1
#
function daemonpid {
 echo `{
	$PS -e | $GREP $1 | $GREP -ve=grep | $CUT -d? -f1
  }` | $CUT -d' ' -f1
}

# validate PID in $1 and return
# PID or zero if the process is not running
#
function running {
  PROCESS=`$PS -p $1 | $TAIL -1 | $GREP $1`
  if [ "`echo $PROCESS | $WC -w`" != "0" ]; then
    echo $1
  else
    echo 0
  fi
}

# DNSBL nameserver must be restarted
  if [ "named" = "$2" ]; then
    if [ "$RNDC" != "" ]; then
      $RNDC restart
      exit 0;
    fi
    PID=$PIDNAMED
    DAEMON=$2 
  else
    PID=$PIDRBLDNS
    DAEMON=rbldnsd
  fi
# try and get the pid of daemon from .pid file or process list
  if [ -e $PID ]; then
    PID=`cat $PID`
    PID=`running $PID`
    if [ "$PID" = "" ] || [ "$PID" =  "0" ]; then
# last gasp try
      PID=`daemonpid $DAEMON`
    fi
  else
    PID=`daemonpid $DAEMON`
  fi

  if [ "$PID" = "" ]; then
    PID=0
  fi

  if [ $PID -ne 0 ]; then
echo "killing $PID"
    $KILL -HUP $PID
    exit 0
  fi

  echo "ERROR: could not find pid of '$DAEMON'"
  exit -1
fi

=pod

=head1 NAME

update_sc.sh -- rsync mirror script

=head1 SYNOPSIS

      for rsync data retrieval
 usage:  update_sc.sh /zonefile/path/targetname bind|ip4set|combined
 i.e.    update_sc.sh /etc/named/master/somedomain.com bind
         update_sc.sh /var/lib/rbldns/some.ip4set.set.rbl ip4set
         update_sc.sh /var/lib/rbldns/some.combined.set.rbl combined

      for HUPing the nameserver daemon
         update_sc.sh HUP named | rbldnsd"

      for bind, we recommend adding "rndc flush 'zonename'"
                to your cron script as well"

=head1 DESCRIPTION

  update_sc.sh takes two mandatory arguments

    1)	the absolute path to the zonefile name on the
	client host. This would be a zonefile path and
	file for the 'named' daemon or an ip4set or
	combined file path for the 'rbldnsd' daemon.

    2)  the word 'bind', 'ip4set', or 'combined'
	to indicate which file to retrieve from 
	rsync.spamcannibal.org

 OR
    1)	the keyword "HUP"

    2)  and the name of the nameserver daemon, one of:

		named
		rbldnsd

The B<update_sc.sh> script can be run manually or by B<crond>

=head1 AUTHOR

Michael Robinton <michael@bizsystems.com>

=head1 COPYRIGHT

Copyright 2006, Michael Robinton <michael@bizsystems.com>
This script is free software; you can redistribute it and/or
modify it under the terms of the GPL software license.

=cut

