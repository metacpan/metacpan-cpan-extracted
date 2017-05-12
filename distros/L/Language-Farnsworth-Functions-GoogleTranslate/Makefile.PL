#!env perl

use strict;  
use warnings;

use inc::Module::Install;

name "Language-Farnsworth-Functions-GoogleTranslate";
all_from       'lib/Language/Farnsworth/Functions/GoogleTranslate.pm';
version_from "lib/Language/Farnsworth/Functions/GoogleTranslate.pm";
license 'artistic';

requires 'REST::Google::Translate' => 0;
requires 'Language::Farnsworth' => 0;

WriteAll;
