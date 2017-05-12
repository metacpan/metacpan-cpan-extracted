#!/usr/bin/env perl
# Try Extract PPI

use warnings;
use strict;

use File::Temp   qw/tempdir/;
use Test::More;

use Log::Report 'my-domain';
use_ok 'Log::Report::Translator::POT';

BEGIN
{   eval "require PPI";
    plan skip_all => 'PPI not installed'
        if $@;

    plan tests => 11;
    use_ok('Log::Report::Extract::PerlPPI');
}

my $lexicon    = tempdir CLEANUP => 1;
#warn "Lexicon at $lexicon";

my $rules =
  { gender => [ 'male', 'female' ]
  , formal => [ 'informal', 'formal' ]
  };

my $domain = textdomain 'my-domain', context_rules => $rules;
isa_ok $domain, 'Log::Report::Domain';

### Create tables

my $ppi = Log::Report::Extract::PerlPPI->new(lexicon => $lexicon);
ok defined $ppi, 'created parser';
isa_ok $ppi, 'Log::Report::Extract::PerlPPI';

$ppi->process( __FILE__ );   # yes, this file!
$ppi->write;

#### 

my $old = textdomain 'my-domain', 'DELETE';   # restart administration
isa_ok $old, 'Log::Report::Domain', 'caught deleted';

my $translator = Log::Report::Translator::POT->new(lexicon => $lexicon);

my $new = textdomain 'my-domain'
  , context_rules => $rules
  , translator    => $translator;

isa_ok $new, 'Log::Report::Domain', 'recreated';
cmp_ok $old, '!=', $new, 'new is really new';

$new->setContext('gender=male,formal=informal');

my $a1 = __x"{name<gender} forgot his key", name => 'Mark';
is $a1, 'Mark forgot his key', 'Mark';

my $a2 = __xn"Dear Sir,{<gender<formal}", "Dear Sirs,", 3;
is $a2, 'Dear Sirs,';

my $a3 = __x"no context {where}", where => 'here';
is $a3, 'no context here';

