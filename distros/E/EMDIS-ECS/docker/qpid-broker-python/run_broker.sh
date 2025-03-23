#!/usr/bin/sh

SASLDB_FILE="${HOME}/pybroker.sasldb"
if [ ! -f "${SASLDB_FILE}" ]; then
  # initialize SASL password file
  echo "Initializing SASL password file:  ${SASLDB_FILE}"
  echo -n password | saslpasswd2 -c -p -f ${SASLDB_FILE} admin
  echo -n password | saslpasswd2 -c -p -f ${SASLDB_FILE} emdis-aa
  echo -n password | saslpasswd2 -c -p -f ${SASLDB_FILE} emdis-dd
  echo -n password | saslpasswd2 -c -p -f ${SASLDB_FILE} emdis-ee
fi

# get (non-loopback) IP address of docker container
BROKER_ADDR=`hostname -i`
echo "BROKER_ADDR:  ${BROKER_ADDR}"

echo "Starting AMQP test broker ..."
CERTFILES_DIR="/home/pybroker/certfiles"
exec /usr/bin/python3 /home/pybroker/pybroker.py \
 --debug 0 \
 --address amqps://${BROKER_ADDR}:5671 \
 --truststore ${CERTFILES_DIR}/test-ca.pem \
 --sslcert ${CERTFILES_DIR}/test-server.pem \
 --sslkey ${CERTFILES_DIR}/test-server-key.pem \
 --sslpass password \
 --sasl_config_path "${HOME}" \
 --sasl_config_name pybroker
