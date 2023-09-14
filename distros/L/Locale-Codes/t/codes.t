#!/usr/bin/perl

use warnings 'all';
use strict;
use Test::Inter;
my $t = new Test::Inter $0;

use Locale::Codes;
my $o;

local $SIG{__WARN__} = sub { my @err = split(/\n/,$_[0]); $::stderr_msg = $err[0] };

sub test {
   my($sub,@test) = @_;
   $::stderr_msg  = '';
   my @ret;

   if ($sub eq 'type') {
      @ret = $o->type(@test);
   } elsif ($sub eq '_code') {
      @ret = $o->_code(@test);
   } elsif ($sub eq 'new') {
      $o = new Locale::Codes(@test);
      @ret = $o->show_errors(0);
   } elsif ($sub eq 'all_names') {
      @ret = $o->all_names();
      if (@ret) {
         my $n = pop(@test);
         @ret = @ret[0..($n-1)];
      }
   } elsif ($sub eq 'all_codes') {
      @ret = $o->all_codes();
      if (@ret) {
         my $n = pop(@test);
         @ret = @ret[0..($n-1)];
      }
   } elsif ($sub eq 'show_errors') {
      @ret = $o->show_errors(@test);
   } elsif ($sub eq 'codeset') {
      @ret = $o->codeset(@test);
   } elsif ($sub eq 'code2code') {
      @ret = $o->code2code(@test);
   } elsif ($sub eq 'code2name') {
      @ret = $o->code2name(@test);
   } elsif ($sub eq 'name2code') {
      @ret = $o->name2code(@test);
   } elsif ($sub eq 'delete_code_alias') {
      @ret = $o->delete_code_alias(@test);
   } elsif ($sub eq 'add_code_alias') {
      @ret = $o->add_code_alias(@test);
   } elsif ($sub eq 'replace_code') {
      @ret = $o->replace_code(@test);
   } elsif ($sub eq 'delete_alias') {
      @ret = $o->delete_alias(@test);
   } elsif ($sub eq 'add_alias') {
      @ret = $o->add_alias(@test);
   } elsif ($sub eq 'delete_code') {
      @ret = $o->delete_code(@test);
   } elsif ($sub eq 'add_code') {
      @ret = $o->add_code(@test);
   } elsif ($sub eq 'rename_code') {
      @ret = $o->rename_code(@test);
   }

   if ($::stderr_msg) {
      chomp($::stderr_msg);
      return $::stderr_msg;
   } else {
      return @ret;
   }
}

my $tests = "

new              => 0

type foo         => 1

_code            => 1

show_errors 1    => 1

type foo         => 'ERROR: type: invalid argument: foo'

_code            => 'ERROR: _code: no type set for Locale::Codes object'

#####

new              => 0

type country     => 0

_code '' alpha-3 => 0 '' alpha-3

_code aa foo     => 1

_code zzz        => 1

_code zzz ''     => 1

_code zz alpha-3 => 1

show_errors 1    => 1

_code aa foo     => 'ERROR: _code: invalid codeset provided: foo'

_code zzz        => 'ERROR: _code: code not in codeset: zzz [alpha-2]'

_code zzz ''     => 'ERROR: _code: code not in codeset: zzz [alpha-2]'

_code zz alpha-3 => 'ERROR: _code: code not in codeset: zz [alpha-3]'

#####

new country alpha-2 0 => 0

codeset alpha-3   => 0

codeset foo       => 1

_code xx numeric  => 1

show_errors 1     => 1

codeset foo       => 'ERROR: codeset: invalid argument: foo'

_code xx numeric  => 'ERROR: _code: invalid numeric code: xx'

#####

new               => 0

code2name xx      => __undef__

name2code xx      => __undef__

show_errors 1     => 1

code2name xx      => 'ERROR: code2name: no type set for Locale::Codes object'

name2code xx      => 'ERROR: name2code: no type set for Locale::Codes object'

#####

new                  => 0

delete_code_alias a  => 0

show_errors 1        => 1

delete_code_alias a  => 'ERROR: delete_code_alias: no type set for Locale::Codes object'

type country         => 0

delete_code_alias a alpha-2  => 'ERROR: delete_code_alias: unknown code/codeset: a [alpha-2]'

delete_code_alias us alpha-2 => 'ERROR: delete_code_alias: no alias defined: us'

show_errors 0        => 0

delete_code_alias a alpha-2  => 0

delete_code_alias us alpha-2 => 0

#####

new                        => 0

add_code_alias a b alpha-2 => 0

show_errors 1              => 1

add_code_alias a b alpha-2 => 'ERROR: add_code_alias: no type set for Locale::Codes object'

type country               => 0

add_code_alias a b alpha-2  => 'ERROR: add_code_alias: unknown code/codeset: a [alpha-2]'

add_code_alias us gb alpha-2 => 'ERROR: add_code_alias: code already in use: gb'

show_errors 0              => 0

add_code_alias a b alpha-2  => 0

add_code_alias us gb alpha-2 => 0

#####

new                      => 0

replace_code a b alpha-2 => 0

show_errors 1            => 1

replace_code a b alpha-2 => 'ERROR: replace_code: no type set for Locale::Codes object'

type country             => 0

add_code_alias us xx alpha-2 => 1

replace_code a b alpha-2 => 'ERROR: replace_code: Unknown code/codeset: a [alpha-2]'

replace_code gb xx alpha-2 => 'ERROR: replace_code: new code already in use as alias: xx'

replace_code gb us alpha-2 => 'ERROR: replace_code: new code already in use: us'

show_errors 0        => 0

replace_code a b alpha-2 => 0

replace_code gb xx alpha-2 => 0

replace_code gb us alpha-2 => 0

#####

new                     => 0

add_alias a b           => 0

show_errors 1           => 1

add_alias a b           => 'ERROR: add_alias: no type set for Locale::Codes object'

type country            => 0

add_alias us xx         => 1

add_alias a b           => 'ERROR: add_alias: name does not exist: a'

add_alias Hungary xx    => 'ERROR: add_alias: alias already in use: xx'

show_errors 0           => 0

add_alias a b           => 0

add_alias Sark xx       => 0

#####

new                     => 0

delete_code a alpha-2   => 0

show_errors 1           => 1

delete_code a alpha-2   => 'ERROR: delete_code: no type set for Locale::Codes object'

type country            => 0

delete_code a alpha-2   => 'ERROR: delete_code: Unknown code/codeset: a [alpha-2]'

show_errors 0           => 0

delete_code a alpha-2   => 0

#####

new                      => 0

add_code a foo alpha-2   => 0

show_errors 1            => 1

add_code a foo alpha-2   => 'ERROR: add_code: no type set for Locale::Codes object'

type country             => 0

add_code_alias us x1     => 1

add_code a foo bar       => 'ERROR: add_code: unknown codeset: bar'

add_code x1 fo alpha-2   => 'ERROR: add_code: code already in use as alias: x1'

add_code x2 Albania alpha-2   => 'ERROR: add_code: name already in use: Albania'

show_errors 0            => 0

add_code a foo bar       => 0

add_code x1 fo alpha-2   => 0

add_code x2 Albania alpha-2   => 0

#####

new                      => 0

rename_code a b alpha-2  => 0

show_errors 1            => 1

rename_code a b alpha-2  => 'ERROR: rename_code: no type set for Locale::Codes object'

type country             => 0

rename_code a b bar      => 'ERROR: rename_code: unknown code/codeset: a [bar]'

rename_code us Hungary alpha-2 => 'ERROR: rename_code: rename to an existing name not allowed'

show_errors 0            => 0

rename_code a b bar      => 0

rename_code us Hungary alpha-2 => 0

#####

new                      => 0

delete_alias a           => 0

show_errors 1            => 1

delete_alias a           => 'ERROR: delete_alias: no type set for Locale::Codes object'

type country             => 0

delete_alias aaa         => 'ERROR: delete_alias: name does not exist: aaa'

delete_alias Albania     => 'ERROR: delete_alias: only one name defined (use delete_code instead)'

show_errors 0            => 0

delete_alias aaa         => 0

delete_alias Albania     => 0

#####

new                      => 0

all_names 2              =>

all_codes 2              =>

show_errors 1            => 1

all_names 2              => 'ERROR: all_names: no type set for Locale::Codes object'

all_codes 2              => 'ERROR: all_codes: no type set for Locale::Codes object'

#####

new                      => 0

code2code                => __undef__

show_errors 1            => 1

code2code                => 'ERROR: code2code: no type set for Locale::Codes object'

";

$t->tests(func  => \&test,
          tests => $tests);
$t->done_testing();
