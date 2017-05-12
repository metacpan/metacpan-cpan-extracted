#!/usr/bin/env bash

git clone git://github.com/travis-perl/helpers ~/travis-perl-helpers
source ~/travis-perl-helpers/init
build-perl
perl -V
build-dist
cd $BUILD_DIR             # $BUILD_DIR is set by the build-dist command

#Install
cpanm --notest Package::DeprecationManager
cpanm --notest --installdeps .
cpanm --quiet --notest --skip-satisfied Dist::Milla
cpan-install --notest Dist::Zilla::Plugin::AutoPrereqs
cpan-install --coverage   # installs converage prereqs, if enabled

#Before Script
coverage-setup

#Run tests
prove -l -j$(test-jobs) $(test-files)   # parallel testing

#After success
coverage-report
