#!/usr/bin/perl -w

use Lingua::StarDict::Gen;
use Biblio::Thesaurus;

$obj = thesaurusLoad('animal.the');

Lingua::StarDict::Gen::escreveDic($obj->{$obj->{baselang}}, "thesaurus-animal");
