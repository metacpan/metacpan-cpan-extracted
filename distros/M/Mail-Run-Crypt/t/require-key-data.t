#!perl -T

use strict;
use warnings;
use utf8;

use English '-no_match_vars';
use Test::More tests => 4;

use Mail::Run::Crypt;

our $VERSION = '0.10';

{
    my $mrc;
    my $error;
    my %opts = (
        mailto     => 'nobody@example.com',
        sign       => 1,
        passphrase => 'faster than the fastest horse alive',
    );
    eval { $mrc = Mail::Run::Crypt->new(%opts) } or $error = $EVAL_ERROR;
    ok( defined $error,                                'no_keyid_failed' );
    ok( $error =~ m/^\QKey ID required for signing/msx, 'no_keyid_errorstr' );
}

{
    my $mrc;
    my $error;
    my %opts = (
        mailto => 'nobody@example.com',
        sign   => 1,
        keyid  => '0x12345678DEADBEEF',
    );
    eval { $mrc = Mail::Run::Crypt->new(%opts) } or $error = $EVAL_ERROR;
    ok( defined $error, 'no_passphrase_failed' );
    ok( $error =~ m/^\QPassphrase required for signing/msx,
        'no_passphrase_errorstr' );
}
