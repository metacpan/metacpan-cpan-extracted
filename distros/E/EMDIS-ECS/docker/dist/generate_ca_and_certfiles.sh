#!/bin/sh -e
# use OpenSSL to construct CA and generate SSL certificate files for server and client

# sanity checks & defaults
if [ -z "${HOME}" ]; then
  echo 'Error:  $HOME not defined.'
  exit 1
fi

if [ -z "${CERTFILES_SUBDIR}" ]; then
  CERTFILES_SUBDIR="certfiles"
fi
if [ -z "${CA_CERT_NAME}" ]; then
  CA_CERT_NAME="test-ca"
fi
if [ -z "${SERVER_CERT_NAME}" ]; then
  SERVER_CERT_NAME="test-server"
fi
if [ -z "${CLIENT_CERT_NAME}" ]; then
  CLIENT_CERT_NAME="test-client"
fi
if [ -z "${CA_CERT_PASSWORD}" ]; then
  CA_CERT_PASSWORD="capwd"
fi
if [ -z "${SERVER_CERT_PASSWORD}" ]; then
  SERVER_CERT_PASSWORD="password"
fi
if [ -z "${CLIENT_CERT_PASSWORD}" ]; then
  CLIENT_CERT_PASSWORD="password"
fi

CERTDIR="${HOME}/$CERTFILES_SUBDIR"

# remove existing artifacts
rm -rf ${CERTDIR}/* ${HOME}/certfiles.tar.gz

# create CERTFILES_SUBDIR
mkdir -p ${CERTDIR}

# Generate CA key and cert
openssl genrsa -aes256 -out ${CERTDIR}/${CA_CERT_NAME}-key.pem -passout pass:${CA_CERT_PASSWORD}
# to view generated key
# openssl rsa -in ${CERTDIR}/${CA_CERT_NAME}-key.pem -passin pass:${CA_CERT_PASSWORD} -text -noout
openssl req -new -x509 -key ${CERTDIR}/${CA_CERT_NAME}-key.pem -passin pass:${CA_CERT_PASSWORD} \
 -subj "/O=EMDIS/OU=ECS/CN=${CA_CERT_NAME}/emailAddress=${CA_CERT_NAME}@ecs.emdis.net" -days 365 \
 -out ${CERTDIR}/${CA_CERT_NAME}.pem
 # to view CA certificate:
 # openssl x509 -in ${CERTDIR}/${CA_CERT_NAME}.pem -text -noout

# Generate server key, cert request, signed cert, and p12 keystore
openssl genrsa -out ${CERTDIR}/${SERVER_CERT_NAME}-key.pem -passout pass:${SERVER_CERT_PASSWORD}
# to view generated key
# openssl rsa -in ${CERTDIR}/${SERVER_CERT_NAME}-key.pem -passin pass:${SERVER_CERT_PASSWORD} -text -noout
openssl req -new -key ${CERTDIR}/${SERVER_CERT_NAME}-key.pem -passin pass:${SERVER_CERT_PASSWORD} \
 -subj "/O=EMDIS/OU=ECS/OU=${CA_CERT_NAME}/CN=${SERVER_CERT_NAME}" \
 -out "${CERTDIR}/${SERVER_CERT_NAME}-req.pem"
# to view certificate request:
# openssl req -in ${CERTDIR}/${SERVER_CERT_NAME}-req.pem -text -noout
openssl x509 -req -inform PEM -in "${CERTDIR}/${SERVER_CERT_NAME}-req.pem" -set_serial 2025041101 \
 -CA "${CERTDIR}/${CA_CERT_NAME}.pem" -CAkey "${CERTDIR}/${CA_CERT_NAME}-key.pem" \
 -passin pass:${CA_CERT_PASSWORD} -days 365 -outform PEM \
 -out "${CERTDIR}/${SERVER_CERT_NAME}.pem"
# to view server certificate:
# openssl x509 -in ${CERTDIR}/${SERVER_CERT_NAME}.pem -text -noout
# create keystore for server (including CA cert)
openssl pkcs12 -export -in "${CERTDIR}/${SERVER_CERT_NAME}.pem" \
 -inkey "${HOME}/${CERTFILES_SUBDIR}/${SERVER_CERT_NAME}-key.pem" \
 -name ${SERVER_CERT_NAME} -certfile "${CERTDIR}/${CA_CERT_NAME}.pem" \
 -caname ${CA_CERT_NAME} -passin pass:${SERVER_CERT_PASSWORD} -passout pass:${SERVER_CERT_PASSWORD} \
 -out "${CERTDIR}/${SERVER_CERT_NAME}.p12"
# to examine p12 file:
# openssl pkcs12 -in ${CERTDIR}/${SERVER_CERT_NAME}.p12 -passin pass:${SERVER_CERT_PASSWORD} -nodes -info

# Generate client key, cert request, signed cert, and p12 keystore
openssl genrsa -out ${CERTDIR}/${CLIENT_CERT_NAME}-key.pem -passout pass:${CLIENT_CERT_PASSWORD}
# to view generated key:
# openssl rsa -in ${CERTDIR}/${CLIENT_CERT_NAME}-key.pem -passin pass:${CLIENT_CERT_PASSWORD} -text -noout
openssl req -new -key ${CERTDIR}/${CLIENT_CERT_NAME}-key.pem -passin pass:${CLIENT_CERT_PASSWORD} \
 -subj "/O=EMDIS/OU=ECS/OU=${CA_CERT_NAME}/CN=${CLIENT_CERT_NAME}" \
 -out "${CERTDIR}/${CLIENT_CERT_NAME}-req.pem"
# to view certificate request:
# openssl req -in ${CERTDIR}/${CLIENT_CERT_NAME}-req.pem -text -noout
openssl x509 -req -inform PEM -in "${CERTDIR}/${CLIENT_CERT_NAME}-req.pem" -set_serial 2025041101 \
 -CA "${CERTDIR}/${CA_CERT_NAME}.pem" -CAkey "${CERTDIR}/${CA_CERT_NAME}-key.pem" \
 -passin pass:${CA_CERT_PASSWORD} -days 365 -outform PEM \
 -out "${CERTDIR}/${CLIENT_CERT_NAME}.pem"
# to view client certificate:
# openssl x509 -in ${CERTDIR}/${CLIENT_CERT_NAME}.pem -text -noout
# create keystore for client (including CA cert)
openssl pkcs12 -export -in "${CERTDIR}/${CLIENT_CERT_NAME}.pem" \
 -inkey "${HOME}/${CERTFILES_SUBDIR}/${CLIENT_CERT_NAME}-key.pem" \
 -name ${CLIENT_CERT_NAME} -certfile "${CERTDIR}/${CA_CERT_NAME}.pem" \
 -caname ${CA_CERT_NAME} -passin pass:${CLIENT_CERT_PASSWORD} -passout pass:${CLIENT_CERT_PASSWORD} \
 -out "${CERTDIR}/${CLIENT_CERT_NAME}.p12"
# to examine p12 file:
# openssl pkcs12 -in ${CERTDIR}/${CLIENT_CERT_NAME}.p12 -passin pass:${CLIENT_CERT_PASSWORD} -nodes -info

# construct certfiles tarball
cd ${CERTDIR}
tar czf ${HOME}/certfiles.tar.gz *

