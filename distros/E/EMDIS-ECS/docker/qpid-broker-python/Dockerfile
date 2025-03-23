# Dockerized Python AMQP test broker for testing AMQP features of Perl ECS ...
#
# For additional information about docker, see https://www.docker.com/
#
# Below are brief notes about using this Dockerfile.
#
# 1) Move to the directory containing this Dockerfile. 
#
#    cd docker/qpid-broker-python
#
# 2) Build a "perlecs/qpid-broker-python" Docker image based on the Dockerfile.
#    If needed, first copy certfiles.tar.gz file from neighboring ../dist
#    directory.
#
#    cp ../dist/certfiles.tar.gz .
#    docker build -t perlecs/qpid-broker-python:0.44-1 .
#
# 3) Run a Docker container based on the image.  This automatically starts the
#    Python AMQP test broker.
#
#    docker run --rm -it --name=perlecs_qpid_broker_py  perlecs/qpid-broker-python:0.44-1
#
# 4) Optionally, open an interactive shell session in the running container
#
#    docker exec -it perlecs_qpid_broker_py /bin/bash
#

# image is based on Rocky Linux 9
FROM rockylinux:9
LABEL Maintainer="Joel Schneider <joel@joelschneider.net>"
LABEL Description="Apache Qpid Broker - Python"
LABEL Version="0.44"

# update installed packages
RUN yum -y update

# install extra Rocky Linux packages
RUN yum -y install less which python3 cyrus-sasl cyrus-sasl-plain

# add EPEL repository and install Mail::IMAPClient from there
RUN yum -y install epel-release
RUN yum -y install python3-qpid-proton

# create perlecs user
RUN useradd --comment "Apache Qpid Python broker user" --create-home pybroker

# define ${HOME} environment variable
ENV HOME=/home/pybroker

USER pybroker
WORKDIR ${HOME}

# (self-signed) certificates needed for SSL
ENV CERTFILES_SUBDIR="certfiles"
COPY --chown=pybroker:pybroker certfiles.tar.gz ./
RUN mkdir -m 755 ./${CERTFILES_SUBDIR}
RUN tar xzf ./certfiles.tar.gz -C ./${CERTFILES_SUBDIR}

# SASL configuration file
COPY --chown=pybroker:pybroker pybroker.conf ./

# Python AMQP test broker and wrapper shell script
COPY --chown=pybroker:pybroker pybroker.py ./
COPY --chown=pybroker:pybroker run_broker.sh ./

#USER root

ENTRYPOINT [ "/usr/bin/sh", "/home/pybroker/run_broker.sh" ]
