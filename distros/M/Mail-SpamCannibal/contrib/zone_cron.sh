#!/bin/sh
#
# zone_cron.sh
#
# version 1.04, 12-7-04, michael@bizsystems.com
#
# dnsbls zone file dump example
#
# 5 minute timeout, extend if necessary
TIMEOUT=900
ZONE_NAME="bl.spamcannibal.org"

DBHOME="/var/run/dbtarpit"
SPAMHOME="/usr/local/spamcannibal"
PID_FILE="dnsbls.pid"
SCRIPT_NAME=${0##*/}

# Get the PID of the dnsbls task
DNSBLS_PID=`cat ${DBHOME}/${PID_FILE}`

echo $$ > ${DBHOME}/${SCRIPT_NAME}.running

# remove old zone file if it's still hanging around
if [ -e ${DBHOME}/${ZONE_NAME}.in ]; then
  rm ${DBHOME}/${ZONE_NAME}.in
fi

# Signal dnsbls task to update zone file
kill -USR2 $DNSBLS_PID

# Wait for zone dump task to complete
while  sleep 1; [ $TIMEOUT -gt 0 ] && [ ! -e ${DBHOME}/${ZONE_NAME}.in ];
do  
  TIMEOUT=$((TIMEOUT - 1))
done

if [ $TIMEOUT -le 0 ]; then

#  a time out error occured
  echo "$0 timeout error"

else

# do something with the zone file such
# as copy it to and export directory

  cp ${DBHOME}/${ZONE_NAME}.in ${SPAMHOME}/public_html
  chmod 644 ${SPAMHOME}/public_html/${ZONE_NAME}.in
# save some space
  rm ${DBHOME}/${ZONE_NAME}.in
fi

rm ${DBHOME}/${SCRIPT_NAME}.running
