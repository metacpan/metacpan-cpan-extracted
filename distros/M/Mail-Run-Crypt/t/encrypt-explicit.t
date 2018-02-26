#!perl -T

use strict;
use warnings;
use utf8;

use Test::More tests => 2;

use Mail::Run::Crypt;

our $VERSION = '0.11';

my %opts = ( mailto => 'nobody@example.com', encrypt => 1 );
my $mrc = Mail::Run::Crypt->new(%opts);
ok( $mrc->{encrypt} == 1, 'encrypt_explicit_encrypt_on' );
ok( $mrc->{sign} == 0,    'encrypt_explicit_sign_off' );
