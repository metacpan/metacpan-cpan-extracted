# This Dockerfile makes it easy to build and test the module from a
# pristine environment.
FROM debian

RUN apt-get update && \
    apt-get -y install --no-install-recommends perl perl-doc less make && \
    rm -rf /var/lib/apt/lists/*

ENV TERM=xterm

RUN mkdir /tmp/module-files
WORKDIR /tmp/module-files
COPY . /tmp/module-files

RUN perl Makefile.PL && \
    make && \
    make test && \
    make install
