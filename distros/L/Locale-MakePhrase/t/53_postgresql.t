#!/usr/local/bin/perl

use strict;
use warnings;
use Test;
use vars qw($test);
BEGIN {

  eval "use DBD::Pg";
  if ($@) {
    plan tests => 0;
    $test = 0;
  } else {
    plan tests => 1;
    $test = 1;
  }
};


if ($test) {
  use Locale::MakePhrase;
  use Locale::MakePhrase::BackingStore::PostgreSQL;
  ok(1);

  $Locale::MakePhrase::DEBUG = 0;
  $Locale::MakePhrase::Utils::DEBUG = 0;
  $Locale::MakePhrase::LanguageRule::DEBUG = 0;
  $Locale::MakePhrase::RuleManager::DEBUG = 0;
  $Locale::MakePhrase::BackingStore::DEBUG = 0;
  $Locale::MakePhrase::BackingStore::PostgreSQL::DEBUG = 0;

# 
#  my $bs = new Locale::MakePhrase::BackingStore::Directory(
#    directory => 't/lang',
#  );
#  ok($bs) or print "Bail out! Failed to locate translation directory.\n";
# 
# 
#  my $mp = new Locale::MakePhrase(
#    language => 'en_au',
#    backing_store => $bs,
#  );
#  ok($mp) or print "Bail out! Failed to make a 'Locale::MakePhrase' instance.\n";
# 
#  my $result;
# 
# 
#  $result = $mp->translate("hi there");
#  ok($result eq "Hello") or print "Bail out! Failed to lookup simple phrase for translation.\n";
# 

}

