#!/usr/bin/env bash

set -x -e

# install conda
curl -O https://repo.continuum.io/miniconda/Miniconda3-latest-MacOSX-x86_64.sh
bash Miniconda3-latest-MacOSX-x86_64.sh -b -p $HOME/anaconda
export PATH=$HOME/anaconda/bin:$PATH

conda config --add channels nyuad-cgsb && \
conda config --add channels conda-forge && \
conda config --add channels defaults && \
conda config --add channels r && \
conda config --add channels bioconda

conda install -y perl perl-app-cpanminus perl-moose perl-test-class-moose perl-path-tiny

#Install
# cpanm --notest Package::DeprecationManager
cpanm --notest --installdeps .
# cpanm --quiet --notest --skip-satisfied Dist::Milla
# cpan-install --notest Dist::Zilla::Plugin::AutoPrereqs
# cpan-install --coverage   # installs converage prereqs, if enabled

#Before Script
# coverage-setup

#Run tests
prove -l -v t/test_class_tests.t

#After success
# coverage-report
