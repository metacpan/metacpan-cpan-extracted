#
# This is a skeleton Dockerfile.
# It is not intended to be small or super nifty, it tries to cache some,
# but it is intended to be easy to go into an environment and poke
# around and edit and less things
#
FROM registry.gitlab.com/opndev/perl5/docker-p5/moosy-development:latest

COPY cpanfile .
RUN docker-cpanm --installdeps --test-only . \
    && docker-cpanm -n --installdeps .

COPY . .
RUN prove -l && docker-cpanm -n .
