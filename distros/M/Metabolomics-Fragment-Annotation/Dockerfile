FROM ubuntu:18.04

# set author
MAINTAINER Franck Giacomoni <franck.giacomoni.fr>

### 
### [CONTAINER CORE FUNCTIONS]: 
###   xxxx
###   xxxx
### [NOTES] 
###   xxxx

RUN apt-get -y update &&\
    apt-get -y install build-essential \
        cpanminus \
        git \
        gzip \
        libtext-csv-perl \
        libxml-twig-perl \
        libfile-share-perl && \
        cpan install ExtUtils::MakeMaker && \
        cpan install File::ShareDir::Install && \
        cpan install Module::Release &&\
        cpan install Module::Release::Git  && \
        cpan install Module::CPANTS::Analyse  && \
        cpan install CPAN::Uploader && \
        cpan install App::CPANTS::Lint  && \
        apt-get autoremove -y && \
        apt-get clean && \
        rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
