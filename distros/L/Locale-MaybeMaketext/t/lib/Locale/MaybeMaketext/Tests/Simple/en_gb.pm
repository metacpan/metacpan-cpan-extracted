## no critic (NamingConventions::Capitalization,Variables::ProhibitPackageVars)
package Locale::MaybeMaketext::Tests::Simple::en_gb;
use parent qw/Locale::MaybeMaketext::Tests::Simple/;
use v5.20.0;
use strict;
use warnings;
use utf8;
our $Encoding = 'utf-8';
our %Lexicon  = (
    '_AUTO'   => 1,
    'testing' => 'Something other here'
);

1;

=encoding utf8

=head1 NAME

Locale::MaybeMaketext::Tests::Simple::en_gb - A dummy file for testing purposes .

=cut
