#!/usr/bin/env perl
# Check the creation of the templater
use warnings;
use strict;

use Test::More;
use Log::Report;

use File::Basename qw(dirname);

dispatcher close => 'default';

(my $incl) = grep -d, 't/templates', 'templates';
$incl or die "where are my templates?";

my $lexicon = dirname($incl) .'/lexicons';
-d $lexicon or mkdir $lexicon or die "$lexicon: $!";

use_ok 'Log::Report::Template';

my $templater = Log::Report::Template->new(INCLUDE_PATH => $incl);
isa_ok $templater, 'Log::Report::Template';

### Construct textdomain 'first'

my $first = $templater->addTextdomain(name => 'first', lexicon => $lexicon);
isa_ok $first, 'Log::Report::Template::Textdomain';

is $first->function, 'loc', 'default function';
ok $first->expectedIn($incl), 'expectedIn';

my $f2 = textdomain 'first';
ok defined $f2, 'recover domain';
is $first, $f2;

#dispatcher close => 'default';

eval { $templater->addTextdomain(name => 'first') };
is $@, "error: extension to domain 'first' already exists\n"
  , 'no redefine';

eval { $templater->addTextdomain(name => 'error1', only_in_directory => '/tmp')};
is $@, "error: directory /tmp not in INCLUDE_PATH, used by addTextdomain(only_in_directory)\n"
  , 'outside INCLUDE_PATH';

#eval { $templater->addTextdomain(name => 'error2') };
#is $@, "error: textdomain 'error2' does not specify the lexicon directory\n"
#  , 'no lexicon';

eval { $templater->addTextdomain(name => 'error3', lexicon => $lexicon) };
is $@, "error: translation function 'loc' already in use by textdomain 'first'\n"
  , 'same function again';


### Construct textdomain 'second'

my $second = $templater->addTextdomain
  ( name     => 'second'
  , lexicon  => $lexicon
  , translation_function => 'S'
  , only_in_directory    => $incl
  );
isa_ok $second, 'Log::Report::Template::Textdomain';

is $second->function, 'S', 'function S';
ok $second->expectedIn($incl), 'expectedIn';
ok ! $second->expectedIn('/tmp'), 'not expectedIn';

done_testing;
