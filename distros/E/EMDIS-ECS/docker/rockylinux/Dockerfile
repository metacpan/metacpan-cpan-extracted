# This file defines a docker image based on Rocky Linux 9 which can be
# used for EMDIS::ECS (Perl ECS).
#
# For additional information about docker, see https://www.docker.com/
#
# Below are brief notes about using this Dockerfile.
#
# 1) Move to the directory containing this Dockerfile.
#
#    cd docker/rockylinux
#
# 2) Build a "perlecs/rockylinux" Docker image based on the Dockerfile.
#
#    docker build -t perlecs/rockylinux:0.49-1 .
#
# 3) Generate a Docker container based on the image, and run an interactive
#    bash shell within the container.
#
#    docker run --rm -it --name=perlecs_rockylinux  perlecs/rockylinux:0.49-1 /bin/bash
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

# image is based on Rocky Linux 9
FROM rockylinux:9
LABEL Maintainer="Joel Schneider <joel@joelschneider.net>"
LABEL Description="EMDIS::ECS (Perl ECS) on Rocky Linux"
LABEL Version="0.49"

# update installed packages
RUN yum -y update

# install extra Rocky Linux packages
RUN yum -y install \
 perl perl-Env perl-Data-Dumper make perl-ExtUtils-MakeMaker perl-CPAN \
 perl-App-cpanminus gcc perl-Test-Simple perl-Authen-SASL perl-libwww-perl \
 perl-LWP-Protocol-https diffutils less which python3 \
 cyrus-sasl cyrus-sasl-plain libusbx

# add EPEL repository and install additional packages from there
RUN yum -y install epel-release
RUN yum -y install pass perl-Mail-IMAPClient python3-qpid-proton
# Note:  The gnupg1 package was removed from the EPEL repository in late
# 2025 (around 2025-11-11, when RHEL 9.7 was released).  However, the EPEL
# archive contains old versions of the gnupg1 RPM package files:
# https://dl.fedoraproject.org/pub/archive/epel/9.6-2025-11-11/
# It is recommended to verify the GPG signature of the RPM package using
# rpm --checksig to ensure its authenticity.

# create perlecs user
RUN useradd --comment "Perl ECS user" --create-home perlecs

# define ${HOME} environment variable
ENV HOME=/home/perlecs

USER perlecs
WORKDIR ${HOME}

# install Authen::SASL::Perl via CPAN (need version >= 2.1800 for XOAUTH2 or OAUTHBEARER)
RUN cpanm --local-lib ${HOME}/perl5lib Authen::SASL::Perl

# as perlecs user, install EMDIS::ECS into local-lib directory
RUN cpanm --local-lib ${HOME}/perl5lib EMDIS::ECS

# set PATH and PERL5LIB environment variables to use
# local-lib directory
ENV PATH=${HOME}/perl5lib/bin:${PATH} \
 PERL5LIB=${HOME}/perl5lib/lib/perl5

#USER root
