# This file defines a docker image based on Ubuntu 16.04 which can be
# used for EMDIS::ECS (Perl ECS).
#
# For additional information about docker, see https://www.docker.com/
#
# Below are brief notes about using this Dockerfile.
#
# 1) Move to the directory containing this Dockerfile.
#
#    cd docker/ubuntu
#
# 2) Build a "perlecs/ubuntu" Docker image based on the Dockerfile.
#
#    docker build -t perlecs/ubuntu:0.40-1 .
#
# 3) Generate a Docker container based on the image, and run an interactive
#    bash shell within the container.
#
#    docker run -t -i --name=perlecs_ubuntu  perlecs/ubuntu:0.40-1 /bin/bash
#
#    Alternatively, restart the container after stopping it.
#
#    docker start -i perlecs_ubuntu
#
# 4) Configure Perl ECS within the docker container.  For example, use
#    "ecs_setup" to generate an ecs.cfg configuration file, "ecstool" to
#    set up the node table, "gpg" to configure the GnuPG keyring,
#    "ecs_scan_mail" to start the mail processing daemon, and "ecs_chk_com"
#    to start the communication status daemon.
#
#    For additional information about Perl ECS, try "perldoc EMDIS::ECS",
#    "perldoc EMDIS::ECS::Config", "perldoc ecstool", etc., or see the
#    EMDIS::ECS documentation on CPAN.  For additional information about
#    ECS, refer to the EMDIS and ECS specifications available from
#    http://emdis.net/.

# image is based on Ubuntu 16.04
FROM ubuntu:16.04
LABEL Maintainer="Joel Schneider <joel@joelschneider.net>"
LABEL Description="EMDIS::ECS (Perl ECS) on Ubuntu"
LABEL Version="0.40"

# install extra Ubuntu packages
RUN apt-get update -y
#RUN apt-get upgrade -y perl-modules
RUN apt-get install -y \
  ca-certificates libmail-imapclient-perl \
  build-essential cpanminus make telnet \
  perl-doc man-db manpages groff-base

# create perlecs user
RUN useradd --comment "Perl ECS user" --create-home perlecs

# define ${HOME} environment variable
ENV HOME=/home/perlecs

# as perlecs user, install latest CPAN versions of some
# Perl modules into local-lib directory (because module
# versions provided by Ubuntu may not support SSL/TLS)
USER perlecs
WORKDIR ${HOME}
RUN mkdir ${HOME}/perl5lib
RUN cpanm --local-lib ${HOME}/perl5lib Net::SMTP~3.05 && \
 cpanm --local-lib ${HOME}/perl5lib Net::POP3~3.06 && \
 cpanm --local-lib ${HOME}/perl5lib IO::Socket::SSL~2.007

# install EMDIS::ECS into local-lib directory
RUN cpanm --local-lib ${HOME}/perl5lib EMDIS::ECS

# set PATH and PERL5LIB environment variables to use
# local-lib directory
ENV PATH=${HOME}/perl5lib/bin:${PATH} \
 PERL5LIB=${HOME}/perl5lib/lib/perl5

#USER root

CMD echo "Welcome to Perl ECS.  To create a configuration file, use ecs_setup."
