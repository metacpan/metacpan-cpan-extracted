=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Nb - Package for language Norwegian Bokmål

=cut

package Locale::CLDR::Locales::Nb;
# This file auto generated from Data\common\main\nb.xml
#	on Sun  7 Jan  2:30:41 pm GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.40.1');

use v5.10.1;
use mro 'c3';
use utf8;
use if $^V ge v5.12.0, feature => 'unicode_strings';
use Types::Standard qw( Str Int HashRef ArrayRef CodeRef RegexpRef );
use Moo;

extends('Locale::CLDR::Locales::No');
has 'algorithmic_number_format_data' => (
    is => 'ro',
    isa => HashRef,
    init_arg => undef,
    default => sub {
        use bigfloat;
        return {
    } },
);

no Moo;

1;

# vim: tabstop=4
