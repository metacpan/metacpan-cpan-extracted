#!perl -w

use strict;
use Test::Simple tests => 8;

use Marathon;

my $marathon = Marathon->new;

ok(defined $marathon);
ok($marathon->isa('Marathon'));
ok(defined $marathon->{_ua});
ok($marathon->{_ua}->isa('LWP::UserAgent'));

# it should take a parameter with a default

ok(defined $marathon->{_url});
ok($marathon->{_url} eq 'http://localhost:8080/');

my $test_ip = 'http://169.254.47.11:8080/';
$marathon = undef;
$marathon = Marathon->new( url => $test_ip );

ok($marathon->{_url} eq $test_ip);

# it should take sloppy urls and fix them

my $sloppy_test_ip = '169.254.11.47:8080';
$marathon = undef;
$marathon = Marathon->new( url => $sloppy_test_ip );

ok($marathon->{_url} eq 'http://' . $sloppy_test_ip . '/');
