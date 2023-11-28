## no critic (NamingConventions::Capitalization,Variables::ProhibitPackageVars)
package Locale::MaybeMaketext::Tests::Integration::en;
use parent qw/Locale::MaybeMaketext::Tests::Integration/;
use v5.20.0;
use strict;
use warnings;
use utf8;
our $Encoding = 'utf-8';
our %Lexicon  = (
    '_AUTO'   => 1,
    'basic'   => 'This is working',
    'testing' => 'Something other here',
);

1;

=encoding utf8

=head1 NAME

Locale::MaybeMaketext::Tests::Integration::en - A dummy file for testing purposes .

=cut
