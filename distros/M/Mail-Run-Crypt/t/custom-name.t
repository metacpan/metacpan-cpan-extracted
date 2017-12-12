#!perl -T

use strict;
use warnings;
use utf8;

use Test::More tests => 2;

use Mail::Run::Crypt;

our $VERSION = '0.10';

my $name = 'mrc_custom';
my %opts = (
    mailto => 'nobody@example.com',
    name   => $name,
);
my $mrc = Mail::Run::Crypt->new(%opts);
ok( defined $mrc,          'constructed' );
ok( $mrc->{name} eq $name, 'custom_name' );
