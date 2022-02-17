#!/usr/bin/env bash

PERL_DIR=/home/tbossert/.plenv/versions/5.32.1/bin
#PERL_DIR=/usr/bin/

# Delete old coverage Data
#$PERL_DIR/cover -delete

# Run tests
#HARNESS_PERL_SWITCHES='-MDevel::Cover=-ignore,^t/,Deanonymize -MDevel::Deanonymize=Fancy|Other'  $PERL_DIR/prove t/ -I lib/ -I ../lib
#HARNESS_PERL_SWITCHES="-MDevel::Cover=-ignore,^t/,Deanonymize"  $PERL_DIR/prove t/ -I lib/ -I ../lib



# Run script
$PERL_DIR/perl -MDevel::Cover=-ignore,^t/,Deanonymize -MDevel::Deanonymize='Fancy|Other' -I lib/ -I ../lib my_program.pl

$PERL_DIR/cover -report html