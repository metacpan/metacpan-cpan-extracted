# Dockerized AMQP 1.0 broker for testing AMQP features of Perl ECS ...
#
# This file defines a docker image which uses Apache Qpid CPP to implement
# an AMQP broker that supports AMQP version 1.0.
#
# For additional information about docker, see https://www.docker.com/
#
# Below are brief notes about using this Dockerfile.
#
# 1) Move to the directory containing this Dockerfile.
#
#    cd docker/qpid-broker-cpp
#
# 2) Build a "perlecs/qpid-broker-cpp" Docker image based on the Dockerfile, e.g.
#
#    docker build -t perlecs/qpid-broker-cpp:0.42-1 .
#
# 3) Run a Docker container based on the image, e.g.
#
#    docker run --rm --name=perlecs_qpid_broker_cpp --expose 5671 --expose 5672 perlecs/qpid-broker-cpp:0.42-1
#
# 4) If needed, start a separate bash shell within the running container and
#    use it to execute commands such as qpid-stat and qpid-config, e.g.
#
#    docker exec -it perlecs_qpid_broker_cpp /bin/bash
#    bash-4.2$ qpid-stat -q -b 'amqps://admin/password@localhost:5671' --sasl-mechanism PLAIN
#    bash-4.2$ qpid-config -b 'amqps://admin/password@localhost:5671' --sasl-mechanism PLAIN add queue emdis.yy.msg --durable
#
# 5) If needed, copy tarball containing CA and client certificate files, e.g.
#
#    docker cp perlecs_qpid_broker_cpp:/var/lib/qpidd/certificates.tar.gz .
#

# image is based on CentOS 7
FROM centos:7
LABEL Maintainer="Joel Schneider <joel@joelschneider.net>" \
      Description="Apache Qpid Broker-CPP" \
      Version="0.42"

# install deltarpm, and update installed packages
RUN yum -y install deltarpm.x86_64
RUN yum -y update

# install extra CentOS packages
RUN yum -y install less which cyrus-sasl cyrus-sasl-plain

# add EPEL repository and install qpid stuff from there
RUN yum -y install epel-release
RUN yum -y install globus-simple-ca \
 qpid-cpp-server qpid-cpp-server-linearstore qpid-proton-cpp qpid-tools

# define ${HOME} environment variable
ENV HOME=/var/lib/qpidd
WORKDIR ${HOME}
USER qpidd

# add CA, server, and client certificates
ENV CERTFILES_SUBDIR="certfiles" \
    CA_CERT_NAME="test-ca" \
    SERVER_CERT_NAME="test-server" \
    CLIENT_CERT_NAME="test-client"
ARG GENERATE_NEW_CERTFILES="NO"
ARG CA_CERT_PASSWORD="password"
ARG SERVER_CERT_PASSWORD="password"
ARG CLIENT_CERT_PASSWORD="password"
RUN mkdir -m 755 ${HOME}/${CERTFILES_SUBDIR}
ADD --chown=qpidd:qpidd certfiles.tar.gz ${HOME}/${CERTFILES_SUBDIR}/
ADD --chown=qpidd:qpidd generate_ca_and_certfiles.sh ${HOME}/
# if GENERATE_NEW_CERTFILES=YES, generate new certs
RUN sh -c 'if [ "${GENERATE_NEW_CERTFILES}" = "YES" ]; then ${HOME}/generate_ca_and_certfiles.sh; fi'

# initialize NSS certificate database for use by qpidd
ENV NSSCERTDB_DIR=${HOME}/nsscertdb \
    NSSCERTDB_PASSFILE=${HOME}/nsscertdb_pass \
    SERVERCERT_PASSFILE=${HOME}/servercert_pass
ARG NSSCERTDB_PASSWORD="password"
# create password files
RUN echo "${NSSCERTDB_PASSWORD}"  > ${NSSCERTDB_PASSFILE} \
 && echo "${SERVERCERT_PASSWORD}" > ${SERVERCERT_PASSFILE}
# initialize nsscertdb directory
RUN mkdir ${NSSCERTDB_DIR} \
 && certutil -N -d ${NSSCERTDB_DIR} -f ${NSSCERTDB_PASSFILE}
# import CA cert
RUN certutil -A -d ${NSSCERTDB_DIR} -f ${NSSCERTDB_PASSFILE} \
 -t CT,C,C -n ${CA_CERT_NAME} -i ${HOME}/${CERTFILES_SUBDIR}/${CA_CERT_NAME}.pem
# import server cert & key (pkcs12 file)
RUN pk12util -d ${NSSCERTDB_DIR} -k ${NSSCERTDB_PASSFILE} \
 -i ${HOME}/${CERTFILES_SUBDIR}/${SERVER_CERT_NAME}.p12 -w ${SERVERCERT_PASSFILE}
#RUN certutil -L -d ${NSSCERTDB_DIR} -f ${NSSCERTDB_PASSFILE}

# configure some SASL usernames & passwords
ARG SASL_PASSWORD_ADMIN="password"
ARG SASL_PASSWORD_AA="password"
ARG SASL_PASSWORD_DD="password"
ARG SASL_PASSWORD_EE="password"
RUN echo "${SASL_PASSWORD_ADMIN}" | saslpasswd2 -c -p -f ${HOME}/qpidd.sasldb -u QPID admin \
 && echo "${SASL_PASSWORD_AA}" | saslpasswd2 -c -p -f ${HOME}/qpidd.sasldb -u QPID emdis-aa \
 && echo "${SASL_PASSWORD_DD}" | saslpasswd2 -c -p -f ${HOME}/qpidd.sasldb -u QPID emdis-dd \
 && echo "${SASL_PASSWORD_EE}" | saslpasswd2 -c -p -f ${HOME}/qpidd.sasldb -u QPID emdis-ee
#RUN sasldblistusers2 -f /var/lib/qpidd/qpidd.sasldb

# briefly start qpidd daemon, create a few queues, then stop daemon
RUN qpidd --protocols amqp0-10 --auth no --log-to-file /var/lib/qpidd/setup.log --log-enable info+ --daemon \
 && qpid-config add queue emdis.aa.doc  --durable \
 && qpid-config add queue emdis.aa.meta --durable \
 && qpid-config add queue emdis.aa.msg  --durable \
 && qpid-config add queue emdis.dd.doc  --durable \
 && qpid-config add queue emdis.dd.meta --durable \
 && qpid-config add queue emdis.dd.msg  --durable \
 && qpid-config add queue emdis.ee.doc  --durable \
 && qpid-config add queue emdis.ee.meta --durable \
 && qpid-config add queue emdis.ee.msg  --durable \
 && qpidd --quit
# qpid-stat -q -b 'amqps://admin/password@localhost:5671' --sasl-mechanism PLAIN

# create customized SASL config (without ANONYMOUS in mech_list)
RUN mkdir "${HOME}/sasl2" \
 && sed -r -e 's/^mech_list:.+/mech_list: DIGEST-MD5 EXTERNAL PLAIN/' \
 < /etc/sasl2/qpidd.conf > "${HOME}/sasl2/qpidd.conf"

# create ACL file to configure access permissions
ENV ACL_FILE="${HOME}/qpidd.acl"
RUN echo "acl allow all access exchange"  > ${ACL_FILE} \
 && echo "acl allow all create queue"     >> ${ACL_FILE} \
 && echo "acl allow all delete queue"     >> ${ACL_FILE} \
 && echo "acl allow all bind exchange"    >> ${ACL_FILE} \
 && echo "acl allow all consume queue"    >> ${ACL_FILE} \
 && echo "acl allow all access queue"     >> ${ACL_FILE} \
 && echo "acl allow all publish exchange" >> ${ACL_FILE} \
 && echo "acl allow all access query"     >> ${ACL_FILE} \
 && echo "acl allow admin@QPID all"       >> ${ACL_FILE} \
 && echo "acl deny-log all all"           >> ${ACL_FILE}
# && echo "acl allow emdis-aa@QPID consume queue name=emdis.aa.doc" >> ${ACL_FILE} \

# this should run as user qpidd
ENTRYPOINT [ "/usr/sbin/qpidd", \
 "--protocols",              "amqp1.0", \
 "--protocols",              "amqp0-10", \
 "--log-enable",             "info+", \
 "--require-encryption",     \
 "--acl-file",               "/var/lib/qpidd/qpidd.acl", \
 "--ssl-cert-db",            "/var/lib/qpidd/nsscertdb", \
 "--ssl-cert-name",          "test-server", \
 "--ssl-cert-password-file", "/var/lib/qpidd/nsscertdb_pass", \
 "--sasl-service-name",      "QPID", \
 "--sasl-config",            "/var/lib/qpidd/sasl2" ]
# --ssl-require-client-authentication
# show queues:
# qpid-stat -q -b 'amqps://emdis-aa/password@localhost:5671' --sasl-mechanism PLAIN
