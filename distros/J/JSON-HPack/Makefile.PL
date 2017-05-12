#!/usr/bin/env perl

use 5.008007;

use strict;
use warnings;

# "Son, when you participate in sporting events,
#  it's not whether you win or lose, it's how drunk you get."
use ExtUtils::MakeMaker;

my ($mm) = $ExtUtils::MakeMaker::VERSION =~ /^([^_]+)/;

# We only use core modules, so you shouldn't have to install anything besides
# Perl 5.8.7!
WriteMakefile(
  NAME         => 'JSON-HPack',
  VERSION_FROM => 'lib/JSON/HPack.pm',
  ABSTRACT     => 'A simple and fast JSON Packer',
  AUTHOR       => 'Venkatakrishnan Ganesh <gvenkat@cpan.org>',
  LICENSE      => 'artistic_2',
  'PREREQ_PM' => {
       'Test::More'  => 0, 
       'common::sense' => 0,
       'JSON::Any'  => 0,
       'Test::Deep' => 0
  }
);

