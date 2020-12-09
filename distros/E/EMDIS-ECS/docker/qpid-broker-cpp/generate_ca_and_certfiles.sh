#!/bin/sh -e
# use SimpleCA and OpenSSL to construct CA and generate SSL certificate files for server and client

# sanity checks
FAIL=0
if [ -z "${HOME}" ]; then
  echo 'Error:  $HOME not defined.'
  FAIL=1
fi
if [ -z "${CERTFILES_SUBDIR}" ]; then
  echo 'Error:  $CERTFILES_SUBDIR not defined.'
  FAIL=1
fi
if [ -z "${CA_CERT_NAME}" ]; then
  echo 'Error:  $CA_CERT_NAME not defined.'
  FAIL=1
fi
if [ -z "${SERVER_CERT_NAME}" ]; then
  echo 'Error:  $SERVER_CERT_NAME not defined.'
  FAIL=1
fi
if [ -z "${CLIENT_CERT_NAME}" ]; then
  echo 'Error:  $CLIENT_CERT_NAME not defined.'
  FAIL=1
fi
if [ -z "${CA_CERT_PASSWORD}" ]; then
  echo 'Error:  $CA_CERT_PASSWORD not defined.'
  FAIL=1
fi
if [ -z "${SERVER_CERT_PASSWORD}" ]; then
  echo 'Error:  $SERVER_CERT_PASSWORD not defined.'
  FAIL=1
fi
if [ -z "${CLIENT_CERT_PASSWORD}" ]; then
  echo 'Error:  $CLIENT_CERT_PASSWORD not defined.'
  FAIL=1
fi
if [ $FAIL -eq 1 ]; then
  echo "Failed to generate new certfiles."
  exit 1
fi

# remove existing artifacts
rm -rf ${HOME}/.globus ${HOME}/$CERTFILES_SUBDIR/* ${HOME}/certfiles.tar.gz

# create CERTFILES_SUBDIR
mkdir -p ${HOME}/${CERTFILES_SUBDIR}

# initialize SimpleCA
grid-ca-create \
 -subject   "cn=${CA_CERT_NAME}, ou=ECS, o=EMDIS" \
 -email     "${CA_CERT_NAME}@ecs.emdis.net" \
 -days      1825 \
 -pass      "${CA_CERT_PASSWORD}"
cp -p ${HOME}/.globus/simpleCA/cacert.pem ${HOME}/${CERTFILES_SUBDIR}/${CA_CERT_NAME}.pem

# server cert:  request, sign, and convert to pkcs12
openssl req -new \
 -subj      "/O=EMDIS/OU=ECS/OU=${CA_CERT_NAME}/CN=${SERVER_CERT_NAME}" \
 -config    ${HOME}/.globus/simpleCA/globus-user-ssl.conf \
 -out       ${HOME}/${CERTFILES_SUBDIR}/${SERVER_CERT_NAME}-request.pem \
 -keyout    ${HOME}/${CERTFILES_SUBDIR}/${SERVER_CERT_NAME}-key.pem \
 -passout   "pass:${SERVER_CERT_PASSWORD}"
grid-ca-sign \
 -in        ${HOME}/${CERTFILES_SUBDIR}/${SERVER_CERT_NAME}-request.pem \
 -out       ${HOME}/${CERTFILES_SUBDIR}/${SERVER_CERT_NAME}.pem \
 -passin    "pass:${CA_CERT_PASSWORD}"
openssl pkcs12 -export \
 -name      ${SERVER_CERT_NAME} \
 -in        ${HOME}/${CERTFILES_SUBDIR}/${SERVER_CERT_NAME}.pem \
 -inkey     ${HOME}/${CERTFILES_SUBDIR}/${SERVER_CERT_NAME}-key.pem \
 -out       ${HOME}/${CERTFILES_SUBDIR}/${SERVER_CERT_NAME}.p12 \
 -passin    "pass:${SERVER_CERT_PASSWORD}" \
 -passout   "pass:${CERT1_PASSWORD}"

# client cert:  request, sign, and convert to pkcs12
openssl req -new \
 -subj      "/O=EMDIS/OU=ECS/OU=${CA_CERT_NAME}/CN=${CLIENT_CERT_NAME}" \
 -config    ${HOME}/.globus/simpleCA/globus-user-ssl.conf \
 -out       ${HOME}/${CERTFILES_SUBDIR}/${CLIENT_CERT_NAME}-request.pem \
 -keyout    ${HOME}/${CERTFILES_SUBDIR}/${CLIENT_CERT_NAME}-key.pem \
 -passout   "pass:${CLIENT_CERT_PASSWORD}"
grid-ca-sign \
 -in        ${HOME}/${CERTFILES_SUBDIR}/${CLIENT_CERT_NAME}-request.pem \
 -out       ${HOME}/${CERTFILES_SUBDIR}/${CLIENT_CERT_NAME}.pem \
 -passin    "pass:${CA_CERT_PASSWORD}"
openssl pkcs12 -export \
 -name      ${CLIENT_CERT_NAME} \
 -in        ${HOME}/${CERTFILES_SUBDIR}/${CLIENT_CERT_NAME}.pem \
 -inkey     ${HOME}/${CERTFILES_SUBDIR}/${CLIENT_CERT_NAME}-key.pem \
 -out       ${HOME}/${CERTFILES_SUBDIR}/${CLIENT_CERT_NAME}.p12 \
 -passin    "pass:${CLIENT_CERT_PASSWORD}" \
 -passout   "pass:${CLIENT_CERT_PASSWORD}"

# construct certfiles tarball
cd ${HOME}/${CERTFILES_SUBDIR}
tar czf ${HOME}/certfiles.tar.gz *

