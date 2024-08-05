#!/usr/bin/env bash

export IP=$( hostname -i )

if [ -f ${LANGERTHA_PROJECT_ROOT}/src/share/banner ]; then

  cat ${LANGERTHA_PROJECT_ROOT}/src/share/banner

fi

echo
echo " IP: $IP"
echo

if [ -z "${LANGERTHA_VERSION}" ]; then

  echo " Development Instance"

  shopt -s histappend
  export PROMPT_COMMAND="history -a; history -c; history -r; $PROMPT_COMMAND"

else

  echo " Version ${LANGERTHA_VERSION}"

fi
echo

exec $@
