#!/usr/bin/env perl
# Check message context parsing and checking

use warnings;
use strict;
use lib 'lib', '../lib';

use Test::More tests => 14;

use Log::Report;
use Log::Report::Translator;
use Log::Report::Translator::Context;

my $rules =
 +{ style   => [ 'informal', 'formal' ]
  , gender  => [ 'male', 'female', 'unknown' ]
  , gender2 => { alternatives => [ 'male', 'female' ] }
  , gender3 =>
      { default =>
          { male    => 'm1'
          , female  => 'f1'
          , unknown => 'm1'
          }
      , nl => { unknown => 'x' }
      }
  };

#use JSON;
#warn JSON->new->pretty->encode(\%config);

my $context = Log::Report::Translator::Context->new(rules => $rules);

is_deeply
    [$context->expand('a{b<gender}c' => 'en')]
  , [ 'a{b}c', [ 'gender=female', 'gender=male', 'gender=unknown' ]]
  , 'simple gender';

is_deeply
    [$context->ctxtFor(__('a{b<gender}c') => 'en', {gender => 'male'})]
  , [ 'a{b}c', 'gender=male' ];


is_deeply
    [$context->expand('a{<style}b' => 'en')]
  , [ 'ab', [ 'style=formal', 'style=informal']]
  , 'simple boolean';

is_deeply
    [$context->ctxtFor(__('a{<style}c') => 'en', {style => 'formal'})]
  , [ 'ac', 'style=formal' ];

is_deeply
    [$context->ctxtFor(__('a{<style}c') => 'en', {style => 'informal'})]
  , [ 'ac', 'style=informal' ];


is_deeply
    [ $context->expand("a{b<gender%2f<style}c" => 'en') ]
  , [ 'a{b%2f}c'
    , [ 'gender=female style=formal'
      , 'gender=female style=informal'
      , 'gender=male style=formal'
      , 'gender=male style=informal'
      , 'gender=unknown style=formal'
      , 'gender=unknown style=informal'
      ]
    ]
  , 'combination explosion';

is_deeply
    [$context->ctxtFor(__('a{b<gender%2f<style}c') => 'en'
       , {gender => 'female', style => 'informal'})]
  , [ 'a{b%2f}c', 'gender=female style=informal' ];


is_deeply
    [$context->expand('{<gender2}a' => 'en')]
  , [ 'a', [ 'gender2=female', 'gender2=male' ] ]
  , 'deeper gender2 alternatives';

is_deeply
    [$context->ctxtFor(__('{<gender2}a') => 'en', {gender2 => 'female'})]
  , [ 'a', "gender2=female" ];


is_deeply
    [$context->expand('a{<gender3}', 'en')]
  , [ 'a', [ 'gender3=f1', 'gender3=m1' ]]
  , 'mapping default';

is_deeply
    [$context->ctxtFor(__('a{<gender3}') => 'en', {gender3 => 'male'})]
  , [ 'a', "gender3=m1" ];

is_deeply
    [$context->ctxtFor(__('a{<gender3}x') => 'en', {gender3 => 'unknown'})]
  , [ 'ax', "gender3=m1" ];


is_deeply
    [$context->expand('c{d<gender3}e', 'nl')]
  , [ 'c{d}e', [ 'gender3=f1', 'gender3=m1', 'gender3=x' ]]
  , 'mapping exception';

is_deeply
    [$context->ctxtFor(__('c{d<gender3}e') => 'nl', {gender3 => 'unknown'})]
  , [ 'c{d}e', "gender3=x" ];

