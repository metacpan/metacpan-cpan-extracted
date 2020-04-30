#
# This is a skeleton Dockerfile.
# It is not intended to be small or super nifty, it tries to cache some,
# but it is intended to be easy to go into an environment and poke
# around and edit and less things
#
FROM registry.gitlab.com/opndev/docker-p5/moosy-development:latest as dependencies

COPY cpanfile .
RUN ./dev-bin/cpanm --installdeps --test-only . \
    && ./dev-bin/cpanm -n --installdeps . \
    && rm -rf $HOME/.cpanm

COPY . .
RUN prove -l \
    && ./dev-bin/cpanm -n . \
    && rm -rf $HOME/.cpanm
