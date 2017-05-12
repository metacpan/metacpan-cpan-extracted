#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;
use Unicornify::URL;

is unicornify_url( email => 'yarrow@hock.com' ),
   'http://unicornify.appspot.com/avatar/c5cf0e825e9757a09c43f08650f46a5f';

is unicornify_url( email => 'yarrow@hock.com', size => 128 ),
   'http://unicornify.appspot.com/avatar/c5cf0e825e9757a09c43f08650f46a5f?s=128';
