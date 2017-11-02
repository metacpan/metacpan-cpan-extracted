#!perl -T

use strict;
use warnings;
use utf8;

use English '-no_match_vars';
use Test::More tests => 2;

use Mail::Run::Crypt;

our $VERSION = '0.09';

my $mrc;
my $error;
eval { $mrc = Mail::Run::Crypt->new() } or $error = $EVAL_ERROR;

ok( defined $error,                     'no_mailto_failed' );
ok( $error =~ m/^\QMAILTO required/msx, 'no_mailto_errorstr' );
