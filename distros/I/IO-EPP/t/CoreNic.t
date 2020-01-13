#!/usr/bin/perl

=encoding utf8

=head1 NAME

CoreNic.t

=head1 DESCRIPTION

Tests for IO::EPP::CoreNic

=head1 AUTHORS

Vadim Likhota <vadiml@cpan.org>

=cut

use Test::Spec;

use strict;
use warnings;

use lib '../lib';

use IO::EPP::Test::Server;


use utf8;

plan tests => 1;

use_ok( 'IO::EPP::CoreNic' );
