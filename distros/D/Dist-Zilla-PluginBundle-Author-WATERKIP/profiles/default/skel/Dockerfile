#
# This is a skeleton Dockerfile.
# It is not intended to be small or super nifty, it tries to cache some,
# but it is intended to be easy to go into an environment and poke
# around and edit and less things
#
FROM perl:latest as dependencies
WORKDIR /tmp/build

ENV NO_NETWORK_TESTING=1 \
    DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y vim-tiny less curl

COPY dev-bin dev-bin

COPY cpanfile .
RUN ./dev-bin/cpanm --installdeps --test-only . \
    && ./dev-bin/cpanm -n --installdeps . \
    && rm -rf $HOME/.cpanm

COPY . .
RUN prove -l \
    && ./dev-bin/cpanm -n . \
    && rm -rf $HOME/.cpanm
