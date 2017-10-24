#!perl -T

use strict;
use warnings;
use utf8;

use English '-no_match_vars';
use Test::More tests => 2;

use Mail::Run::Crypt;

our $VERSION = '0.08';

my $mrc;
my $error;
eval { $mrc = Mail::Run::Crypt->new() } or $error = $EVAL_ERROR;

ok( defined $error,                     'no_mailto_failed' );
ok( $error =~ m/^\Qmailto required/msx, 'no_mailto_errorstr' );
