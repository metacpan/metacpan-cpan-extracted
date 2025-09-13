# This file defines a docker image based on CentOS 7 which can be
# used for EMDIS::ECS (Perl ECS).
#
# For additional information about docker, see https://www.docker.com/
#
# Below are brief notes about using this Dockerfile.
#
# 1) Move to the directory containing this Dockerfile.
#
#    cd docker/centos
#
# 2) Build a "perlecs/centos" Docker image based on the Dockerfile.
#
#    docker build -t perlecs/centos:0.46-1 .
#
# 3) Generate a Docker container based on the image, and run an interactive
#    bash shell within the container.
#
#    docker run --rm -it --name=perlecs_centos  perlecs/centos:0.46-1 /bin/bash
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

# image is based on CentOS 7
# Note:  CentOS 7 went into EOL on June 30, 2024
FROM centos:7
LABEL Maintainer="Joel Schneider <joel@joelschneider.net>"
LABEL Description="EMDIS::ECS (Perl ECS) on CentOS"
LABEL Version="0.46"

# hack yum config for post-EOL CentOS 7
# see also https://superuser.com/questions/1373881/centos-7-cannot-find-a-valid-baseurl-for-repo-base-7-x86-64-when-i-run-yum-upda
RUN sed -i -e 's/^mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-Base.repo
RUN sed -i -e 's/^#baseurl=http:\/\/mirror./baseurl=https:\/\/vault./g' /etc/yum.repos.d/CentOS-Base.repo
RUN yum clean all
RUN yum makecache

# install deltarpm, and update installed packages
RUN yum -y install deltarpm
RUN yum -y update

# install extra CentOS packages
RUN yum -y install \
 perl perl-Env perl-Data-Dumper make perl-ExtUtils-MakeMaker perl-CPAN \
 perl-App-cpanminus gcc perl-Test-Simple perl-Authen-SASL less which \
 python3 cyrus-sasl cyrus-sasl-plain

# add EPEL repository and install Mail::IMAPClient from there
RUN yum -y install epel-release
RUN yum -y install perl-Mail-IMAPClient python36-qpid-proton

# create perlecs user
RUN useradd --comment "Perl ECS user" --create-home perlecs

# define ${HOME} environment variable
ENV HOME=/home/perlecs

# as perlecs user, install latest CPAN versions of some
# Perl modules into local-lib directory (because module
# versions provided by CentOS may not support SSL/TLS)
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
