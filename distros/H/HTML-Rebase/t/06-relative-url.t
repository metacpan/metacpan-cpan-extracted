#!perl -wT
use strict;
use Test::More tests => 2;

use HTML::Rebase;
use URI::URL;

*relative_url = \&HTML::Rebase::relative_url;

is relative_url( 'https://localhost:5000/', URI::URL->new('https://localhost:5000/css/hero.jpg')), 'css/hero.jpg', "Strip host+port";
is relative_url( 'https://localhost:5000/foo/', URI::URL->new('https://localhost:5000/css/hero.jpg')), '../css/hero.jpg', "Go upwards";
