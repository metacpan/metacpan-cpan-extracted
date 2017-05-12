#!/usr/bin/env perl
# This tries to use context dependent translations

use warnings;
use strict;

use Test::More;

use Log::Report '12test';

use File::Spec::Functions qw/catdir/;
use File::Basename        qw/dirname/;
use POSIX                 qw/:locale_h/;

# The test file was produced by the t/11 script, and then filled in by hand

if($^O eq 'openbsd')
{   plan skip_all => "openbsd does not support LC_ALL";
    exit 0;
}

my $got_locale = setlocale LC_ALL, 'en_US.UTF-8';
$got_locale && $got_locale eq 'en_US.UTF-8'
    or plan skip_all => "cannot set an en_US.UTF-8 locale";

plan tests => 16;

use_ok('Log::Report::Translator::POT');

my $rules =
  { gender  => [ 'male', 'female' ]
  , style   => [ 'informal', 'formal' ]
  };

my $translator = Log::Report::Translator::POT->new
  ( lexicon => (dirname __FILE__)
  );

my $domain = textdomain '12test'
  , context_rules => $rules
  , translator    => $translator;

isa_ok $domain, 'Log::Report::Domain', 'recreated';

$domain->setContext('gender=male, style=informal');

#
# Simpelest, no context
#

my $d1 = __x"no context {where}", where => 'here';
is $d1, 'out of context here';

#
# Single context "gender", various parameter formats
#

my $a1 = __x"{name<gender} forgot his key", name => 'Mark';
is $a1, 'Mark forgot his key';

my $a2 = __x"{name<gender} forgot his key", name => 'Cleo'
   , _context => 'gender=female';
is $a2, 'Cleo forgot her key';

my $a3 = __x"{name<gender} forgot his key", name => 'Hillary'
   , _context => {gender =>'female'};
is $a3, 'Hillary forgot her key';

my $a4 = __x"{name<gender} forgot his key", name => 'Piet'
   , _context => {gender => 'male'};
is $a4, 'Piet forgot his key';

#
# Two contexts and count
#

my $b1 = __xn"Dear Sir,{<gender<style}", "Dear Sirs,", 3;
is $b1, 'Hi friends,';

my $b2 = __xn"Dear Sir,{<gender<style}", "Dear Sirs,", 3
  , _context => 'gender=female';
is $b2, "Hi darlin's,";

my $b3 = __xn"Dear Sir,{<gender<style}", "Dear Sirs,", 3
  , _context => 'style=formal';
is $b3, 'Dear Sirs,';

my $b4 = __xn"Dear Sir,{<gender<style}", "Dear Sirs,", 3
  , _context => 'gender=female,style=formal';
is $b4, 'Dear Ladies,';



my $b5 = __xn"Dear Sir,{<gender<style}", "Dear Sirs,", 1;
is $b5, 'Dear friend,';

my $b6 = __xn"Dear Sir,{<gender<style}", "Dear Sirs,", 1
  , _context => 'gender=female';
is $b6, "Hi love,";

my $b7 = __xn"Dear Sir,{<gender<style}", "Dear Sirs,", 1
  , _context => 'style=formal';
is $b7, 'Dear Sir,';

my $b8 = __xn"Dear Sir,{<gender<style}", "Dear Sirs,", 1
  , _context => 'gender=female,style=formal';
is $b8, 'Dear Lady,';


# Context values also available to insert

my $c1 = __x"{name} is a {gender}", name => 'Piet'
   , _context => {gender => 'male'};
is $c1, 'Piet is a male';

