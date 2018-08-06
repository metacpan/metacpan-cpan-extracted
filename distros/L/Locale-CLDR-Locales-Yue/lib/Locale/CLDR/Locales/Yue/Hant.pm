=head1

Locale::CLDR::Locales::Yue::Hant - Package for language Cantonese

=cut

package Locale::CLDR::Locales::Yue::Hant;
# This file auto generated from Data\common\main\yue_Hant.xml
#	on Sun  5 Aug  6:29:02 pm GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.33.0');

use v5.10.1;
use mro 'c3';
use utf8;
use if $^V ge v5.12.0, feature => 'unicode_strings';
use Types::Standard qw( Str Int HashRef ArrayRef CodeRef RegexpRef );
use Moo;

extends('Locale::CLDR::Locales::Yue');
no Moo;

1;

# vim: tabstop=4
