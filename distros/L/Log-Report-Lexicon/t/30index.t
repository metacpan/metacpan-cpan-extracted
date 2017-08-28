#!/usr/bin/env perl
# Try Lexicon index: discover files and character encodings

use warnings;
use strict;
use lib 'lib', '../lib';
use utf8;

use Test::More tests => 59;
use File::Basename        qw/dirname/;
use File::Spec::Functions qw/catfile/;

use_ok 'Log::Report::Translator::POT';
use_ok 'Log::Report::Lexicon::Index';

my $lexdir  = dirname(__FILE__);
my $pot     = Log::Report::Translator::POT->new(lexicons => $lexdir);
isa_ok $pot, 'Log::Report::Translator::POT';

my @lexicons = $pot->lexicons;
cmp_ok scalar @lexicons, '==', 1, 'found 1 lexicon';

my $lexicon = shift @lexicons;
isa_ok $lexicon, 'Log::Report::Lexicon::Index';
is $lexicon->directory, $lexdir;

my $i = $lexicon->index;

#use Data::Dumper;
#warn Dumper $i;

### test the list() method

my @list1 = $lexicon->list('simplecal');
cmp_ok scalar @list1, '==', 13, 'list simplecal';

my @list2 = $lexicon->list('simplecal', 'po');
cmp_ok scalar @list2, '==', 12, 'list simplecal po';


### test the find() method

my $fn0 = $lexicon->find('simplecal', 'nl');
ok defined $fn0, "found NL in $fn0";

my $fn1 = $lexicon->find('simplecal', 'nl_BE');
ok defined $fn1, "found nl_BE in $fn1";


### get file opened with correct charset

my @pots =
  ( [ ar    => 'iso-8859-6' => 'نوفمبر'   ]
  , [ ar_sa => 'iso-8859-6' => 'تشرين الثاني' ]
  , [ cs    => 'UTF-8'      => 'Prosinec' ]
  , [ de    => 'iso-8859-1' => 'November' ]
  , [ de_at => 'iso-8859-1' => ''         ]
  , [ fr    => 'iso-8859-1' => 'novembre' ]
  , [ ga    => 'iso-8859-1' => 'Mí na Samhna' ]
  , [ it    => 'iso-8859-1' => 'novembre' ]
  , [ nl    => 'iso-8859-1' => 'november' ]
  , [ pt    => 'iso-8859-1' => 'Novembro' ]
  , [ pt_br => 'iso-8859-1' => 'novembro' ]
  , [ ru    => 'ISO-8859-5' => 'Ноября'   ]
  );

foreach (@pots)
{    my ($lang, $charset, $trans) = @$_;
     my $po = $pot->load('simplecal', $lang);
     ok defined $po, "got translation for $lang";

     isa_ok $po, $lang eq 'ar_sa'
       ? 'Log::Report::Lexicon::MOTcompact'
       : 'Log::Report::Lexicon::POTcompact'; 

     is $po->originalCharset, $charset, 'charset';
     is $po->msgid('November'), $trans, 'translated';
}

my $msg = {_domain => 'simplecal', _msgid => 'November'};
is $pot->translate($msg, 'ru', undef), 'Ноября';
