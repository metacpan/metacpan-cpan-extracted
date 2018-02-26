#!perl -T

use strict;
use warnings;
use utf8;

use Test::More tests => 10;

use Mail::Run::Crypt;

our $VERSION = '0.11';

my %opts = ( mailto => 'nobody@example.com' );
my $mrc = Mail::Run::Crypt->new(%opts);

my $pkg = 'Mail::Run::Crypt';
ok( defined $mrc, 'constructed' );
isa_ok( $mrc, $pkg );
can_ok( $pkg, 'run', 'bail', '_mail' );
ok( $mrc->bail == $Mail::Run::Crypt::DEFAULT_EXIT, 'bail_default_exit' );
ok( $mrc->{mailto} eq $opts{mailto},               'mailto_set' );
ok( $mrc->{encrypt} == 1,                          'encrypt_on' );
ok( $mrc->{sign} == 0,                             'sign_off' );
ok( $mrc->{name} eq $pkg,                          'default_name' );
ok( !defined $mrc->{keyid},                        'keyid unset' );
ok( !defined $mrc->{passphrase},                   'passphrase unset' );
