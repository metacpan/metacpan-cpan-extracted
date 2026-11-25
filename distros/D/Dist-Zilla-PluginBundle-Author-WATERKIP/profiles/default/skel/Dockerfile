# This is a default dockerfile for perl project based on the latest perl
# version
# You can pick from the following list:
#
# * development
# * objectpad, moo, moosy, mojo, fat, waya
#
# Most versions have -development tag
#
# For a private darkpan, use
# minicpan, orepan2
#
FROM registry.gitlab.com/opndev/perl5/docker-p5:latest

COPY cpanfile .
RUN docker-cpanm -n --installdeps .

COPY . .
RUN prove -l && docker-cpanm -n .
