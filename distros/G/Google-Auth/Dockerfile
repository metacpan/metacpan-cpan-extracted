# syntax=docker/dockerfile:1
FROM debian:stable

#LICENSE AND COPYRIGHT
#Copyright (C) 2020,2021,2022 Google, LLC
#This program is released under the following license: Apache 2.0

# Install dependencies and then clean up the image
RUN apt-get update && \
    apt-get install -y \
            gcc \
            libcrypt-x509-perl \
            libcryptx-perl \
            libdatetime-perl \
            libdevel-leak-perl \
            libinline-c-perl \
            libipc-run-perl \
            libjson-xs-perl \
            liblocal-lib-perl \
            libmodule-build-tiny-perl \
            libmodule-pluggable-perl \
            libnet-http-perl \
            libnet-ssleay-perl \
            libscope-guard-perl \
            libssl-dev \
            libsub-info-perl \
            libterm-table-perl \
            libtest-exception-perl \
            libtest-lwp-useragent-perl \
            libtest-simple-perl \
            libtest-taint-perl \
            libtest-warn-perl \
            libthrowable-perl \
            libwww-perl \
	    cpanminus && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/{*InRelease,*_Packages,Contents-*.lz4,Translation-en*,Contents-*.diff_Index,Sources*}

RUN cpanm --local-lib=~/perl5 local::lib && eval $(perl -I ~/perl5/lib/perl5/ -Mlocal::lib)

RUN cpanm Mutex

RUN cpanm Crypt::OpenSSL::CA
