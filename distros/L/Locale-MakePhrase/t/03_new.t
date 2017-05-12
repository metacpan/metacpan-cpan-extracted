#!/usr/bin/perl

use strict;
use warnings;
use Test;
BEGIN { plan tests => 4 };

# Lets try something simple - lets just load the main modules
use Locale::MakePhrase::LanguageRule;
use Locale::MakePhrase::RuleManager;
use Locale::MakePhrase::BackingStore;
use Locale::MakePhrase;
ok(1);

$Locale::MakePhrase::DEBUG = 0;
$Locale::MakePhrase::Utils::DEBUG = 0;
$Locale::MakePhrase::LanguageRule::DEBUG = 0;
$Locale::MakePhrase::RuleManager::DEBUG = 0;
$Locale::MakePhrase::BackingStore::DEBUG = 0;



{
  my $lr = new Locale::MakePhrase::LanguageRule(
    key => 'testing',
    language => 'en',
    rule => '',
    order => 0,
    translation => 'tested',
  );
  ok($lr) or print "Bail out! Failed to make a 'Locale::MakePhrase::LanguageRule' instance.\n";
}

{
  my $rm = new Locale::MakePhrase::RuleManager();
  ok($rm) or print "Failed to make a 'Locale::MakePhrase::RuleManager' instance.\n";
}

{
  my $mp = new Locale::MakePhrase(language => 'en');
  ok($mp) or print "Failed to make a 'Locale::MakePhrase' instance.\n";
}

