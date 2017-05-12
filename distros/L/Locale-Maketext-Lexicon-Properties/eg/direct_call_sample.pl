#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/../lib";

use Locale::Maketext::Lexicon::Properties;
my %lexicon = %{ Locale::Maketext::Lexicon::Properties->parse(<DATA>) };
print $lexicon{foo};
__DATA__
foo=bar
baz=qux
