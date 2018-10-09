=encoding utf8

=head1

Locale::CLDR::Locales::Zh::Hans - Package for language Chinese

=cut

package Locale::CLDR::Locales::Zh::Hans;
# This file auto generated from Data\common\main\zh_Hans.xml
#	on Sun  7 Oct 11:09:41 am GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.33.1');

use v5.10.1;
use mro 'c3';
use utf8;
use if $^V ge v5.12.0, feature => 'unicode_strings';
use Types::Standard qw( Str Int HashRef ArrayRef CodeRef RegexpRef );
use Moo;

extends('Locale::CLDR::Locales::Zh');
no Moo;

1;

# vim: tabstop=4
