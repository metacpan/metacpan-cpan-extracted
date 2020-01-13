#!/usr/bin/perl

=encoding utf8

=head1 NAME

CoCCA.t

=head1 DESCRIPTION

Tests for IO::EPP::CoCCA

=head1 AUTHORS

Vadim Likhota <vadiml@cpan.org>

=cut

use Test::Spec;

use strict;
use warnings;

use lib '../lib';

plan tests => 1;

use_ok( 'IO::EPP::CoCCA' );

