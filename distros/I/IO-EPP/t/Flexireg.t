#!/usr/bin/perl

=encoding utf8

=head1 NAME

Flexireg.t

=head1 DESCRIPTION

Tests for IO::EPP::Flexireg

=head1 AUTHORS

Vadim Likhota <vadiml@cpan.org>

=encoding utf8

ok

=cut

use Test::Spec;

use strict;
use warnings;

use lib '../lib';

use IO::EPP::Test::Server;


no utf8; # !!!

plan tests => 1;

use_ok( 'IO::EPP::Flexireg' );

