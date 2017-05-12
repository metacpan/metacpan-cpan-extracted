#!/usr/bin/perl -l

use strict;
use warnings FATAL => 'all';
use lib '../lib';
use Math::Fraction::Egyptian 'to_egyptian';

my ($numer, $denom) = @ARGV;

my @egypt = to_egyptian($numer,$denom);

print "@egypt";

=pod

=head1 NAME

egyptian.pl - command-line interface to module Math::Fraction::Egyptian

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

