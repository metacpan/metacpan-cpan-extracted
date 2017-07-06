#!/usr/bin/env perl
# Check the extraction of po-tables
use warnings;
use strict;

use lib 'lib';

use Test::More;
#use Log::Report mode => 'DEBUG';
use File::Basename qw(dirname);

(my $incl) = grep -d, 't/templates', 'templates';
$incl or die "where are my templates?";

my $lexicon = dirname($incl) .'/lexicons';
-d $lexicon or mkdir $lexicon or die "$lexicon: $!";

### Construct templater (tested in t/10templater.t)

use_ok 'Log::Report::Template';

my $templater = Log::Report::Template->new
  ( INCLUDE_PATH => $incl
# , DEBUG => 255
  );
isa_ok $templater, 'Log::Report::Template';

my $first = $templater->addTextdomain
  ( name => 'first'
  , lexicon              => $lexicon
  );

isa_ok $first, 'Log::Report::Template::Textdomain';

#dispatcher close => 'default';

my $second = $templater->addTextdomain
  ( name                 => 'second'
  , translation_function => 'S'
  , only_in_directory    => $incl
  , lexicon              => $lexicon
  );

### Extract from the template files

$templater->extract
  (  show_stats => 1
  );

done_testing;
