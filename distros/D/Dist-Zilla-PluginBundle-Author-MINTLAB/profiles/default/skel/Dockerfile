#
# This is a skeleton Dockerfile.
# It is not intended to be small or super nifty, it tries to cache some,
# but it is intended to be easy to go into an environment and poke
# around and edit and less things
#
FROM perl:latest

RUN apt-get update && apt-get install -y vim-tiny less curl

ENV NO_NETWORK_TESTING=1 \
    DEBIAN_FRONTEND=noninteractive

WORKDIR /tmp/build

COPY dev-bin dev-bin

COPY cpanfile .

RUN ./dev-bin/cpanm --installdeps .

# Install ourselves
COPY . .
RUN ./dev-bin/cpanm .

