#!/usr/bin/perl

use strict;
use warnings;
use Test;

use vars qw(@MODULES);
BEGIN {
  @MODULES = qw(
    Locale::MakePhrase::Utils
    Locale::MakePhrase::Numeric
    Locale::MakePhrase::RuleManager
    Locale::MakePhrase::LanguageRule
    Locale::MakePhrase::Language
    Locale::MakePhrase::Language::en
    Locale::MakePhrase::BackingStore
    Locale::MakePhrase::BackingStore::File
    Locale::MakePhrase::BackingStore::Directory
    Locale::MakePhrase::BackingStore::Cached
    Locale::MakePhrase
  );

  eval "use DBD::Pg";
  push @MODULES, qw(Locale::MakePhrase::BackingStore::PostgreSQL) unless $@;

  plan tests => scalar(@MODULES);
};

foreach my $module (@MODULES) {
  eval "use $module";
  ok(! $@) or print "Bail out! Cant load module: $module\n";
}

#
# Notes:
# - We cannot try to load Locale::MakePhrase::Print as it does some funky stuff on load.
#
