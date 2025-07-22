# This file defines a docker image for generating EMDIS::ECS (Perl ECS)
# distribution artifacts such as the PDF documentation and tarball package,
# and for testing EMDIS::ECS email communications.
#
# For additional information about docker, see https://www.docker.com/
#
# Below are brief notes about using this Dockerfile.
#
# 1) Move to the directory containing this Dockerfile.
#
#    cd docker/dist
#
# 2) Build a "perlecs/dist" Docker image based on the Dockerfile.
#
#    docker build -t perlecs/dist:0.45-1 .
#
#    Optionally, use --build-arg to override the TAGGED_VERSION environment
#    variable at build time.
#
#    docker build --build-arg TAGGED_VERSION=0.42 -t perlecs/dist:0.45-1 .
#
# 3) Generate a Docker container based on the image, and run an interactive
#    bash shell within the container.
#
#    docker run --rm -t -i --name=perlecs_dist perlecs/dist:0.45-1 /bin/bash
#
#    If the container will be used for email and AMQP testing, e.g. in
#    conjunction with dockerized email server and amqp broker, use docker
#    inspect to get the IP addresses of those containers.  Then, when starting
#    the perlecs_dist container, use --add-host options to define IP address
#    mappings for the hostnames email-server and amqp-broker.
#
#    docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' perlecs_greenmail
#
#    docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' perlecs_qpid_broker_py
#    (optionally, use perlecs_qpid_broker_cpp AMQP broker instead of perlecs_qpid_broker_py)
#
#    docker run --rm -t -i --name=perlecs_dist --add-host email-server:172.17.0.2 --add-host amqp-broker:172.17.0.3 perlecs/dist:0.45-1 /bin/bash
#
#    The container includes subdirectories containing test configurations to
#    facilitate testing of email communications.  The test configurations
#    require SMTP, POP3, and IMAP email services, typically provided by a
#    companion GreenMail container.  See below for a few example test commands
#    (execute these within the container).
#
#    perldoc EMDIS::ECS
#    cd ecs-AA
#    ecstool --view
#    ecs_scan_mail --once
#    cat ecs_scan_mail.log
#    ecs_chk_com --once
#    cat ecs_chk_com.log
#
# 4) Use Docker commands to copy the generated Perl ECS artifacts from the
#    container to the Docker host (execute these commands on the host).
#
#    docker cp perlecs_dist:/home/perlecs/EMDIS-ECS-0.45/EMDIS-ECS-0.45.tar.gz .
#    docker cp perlecs_dist:/home/perlecs/EMDIS-ECS-0.45/perlecs-0.45.pdf .
#
# 5) If needed, use generate_ca_and_certfiles.sh script to generate new
#    (self signed) SSL certificates, then copy tarball containing certificate
#    files to other places.  E.g.
#
#    (within Docker container)
#    ./generate_ca_and_certfiles.sh
#
#    (on Docker host)
#    docker cp perlecs_dist:/home/perlecs/certificates.tar.gz .
#    cp certificates.tar.gz docker/qpid-broker-cpp
#    cp certificates.tar.gz docker/qpid-broker-python
#

# image is based on Rocky Linux 9
FROM rockylinux:9
LABEL Maintainer="Joel Schneider <joel@joelschneider.net>"
LABEL Description="EMDIS::ECS (Perl ECS) distribution builder and test setup"
LABEL Version="0.45"

# update installed packages
RUN yum -y update

# install extra CentOS packages
RUN yum -y install \
 perl perl-Env perl-Data-Dumper make perl-ExtUtils-MakeMaker perl-CPAN \
 perl-App-cpanminus gcc perl-Test-Simple perl-Authen-SASL perl-libwww-perl \
 perl-LWP-Protocol-https diffutils less which python3 \
 cyrus-sasl cyrus-sasl-plain

# install subversion
RUN yum -y install subversion

# install LaTeX, etc. software for generating PDF from embedded
# Perl POD documentation
RUN yum -y install \
 texlive-scheme-basic \
 texlive-collection-basic \
 texlive-collection-fontsrecommended \
 texlive-collection-latex \
 texlive-collection-latexrecommended

# add EPEL repository and install additional packages from there
RUN yum -y install epel-release
RUN yum -y install pass perl-Mail-IMAPClient python3-qpid-proton

# create perlecs user
RUN useradd --comment "Perl ECS user" --create-home perlecs

# define ${HOME} environment variable
ENV HOME=/home/perlecs

USER perlecs
WORKDIR ${HOME}
RUN mkdir ${HOME}/perl5lib

# install Authen::SASL::Perl via CPAN (need version >= 2.1800 for XOAUTH2 or OAUTHBEARER)
RUN cpanm --local-lib ${HOME}/perl5lib Authen::SASL::Perl
# install Pod::LaTeX via CPAN
RUN cpanm --local-lib ${HOME}/perl5lib Pod::LaTeX

# set PATH and PERL5LIB environment variables to use
# local-lib directory
ENV PATH=${HOME}/perl5lib/bin:${PATH} \
    PERL5LIB=${HOME}/perl5lib/lib/perl5

# overridable at Docker build time, via docker build --build-arg <varname>=<value>
ARG TAGGED_VERSION=0.45

# Export tagged version of the Perl ECS code from the Subversion repository.
RUN svn export https://svn.code.sf.net/p/perlecs/code/tags/EMDIS-ECS-${TAGGED_VERSION}

# Move to the subdirectory containing the exported code, build it, run tests,
# and generate the tarball package.
WORKDIR ${HOME}/EMDIS-ECS-${TAGGED_VERSION}
RUN perl Makefile.PL
RUN make
RUN make test
RUN make dist
RUN if [ ! -e EMDIS-ECS-${TAGGED_VERSION}.tar.gz ]; then \
 mv EMDIS-ECS-*.tar.gz EMDIS-ECS-${TAGGED_VERSION}.tar.gz ; fi

# Generate PDF documentation, and rename the generated PDF file to indicate
# the version.
RUN ./generate_pdf.sh ${TAGGED_VERSION}
RUN mv perlecs.pdf perlecs-${TAGGED_VERSION}.pdf

# install EMDIS::ECS from tarball into local-lib directory
RUN cpanm --local-lib ${HOME}/perl5lib EMDIS-ECS-${TAGGED_VERSION}.tar.gz

# return to HOME directory
WORKDIR ${HOME}

# script to generate new certfiles, for use if/when the old certs expire
ADD --chown=perlecs:perlecs generate_ca_and_certfiles.sh ${HOME}/

# add GnuPG and EMDIS::ECS test configurations, and README
# (use tar commands instead of ADD, to set perlecs:perlecs file ownership)
COPY --chown=perlecs:perlecs certfiles.tar.gz ./
RUN mkdir -m 755 ./certfiles
RUN tar xzf ./certfiles.tar.gz -C ./certfiles
COPY --chown=perlecs:perlecs gnupg.tar.gz ./
RUN tar xzf ./gnupg.tar.gz -C ./
COPY --chown=perlecs:perlecs ecs-AA.tar.gz ecs-BB.tar.gz ecs-CC.tar.gz ecs-DD.tar.gz ecs-EE.tar.gz ./
RUN tar xzf ecs-AA.tar.gz
RUN tar xzf ecs-BB.tar.gz
RUN tar xzf ecs-CC.tar.gz
RUN tar xzf ecs-DD.tar.gz
RUN tar xzf ecs-EE.tar.gz
COPY --chown=perlecs:perlecs README README_GPG README_SMOKE_TESTING ./

#USER root
