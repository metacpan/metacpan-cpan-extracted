FROM michaelpc/perl-base:latest

RUN cpanm --notest -v Dist::Zilla

## Install Modules
ENTRYPOINT [ "/usr/bin/dumb-init" ]

VOLUME /app

WORKDIR /app
