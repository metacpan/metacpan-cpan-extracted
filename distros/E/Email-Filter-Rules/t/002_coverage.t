#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 12;

BEGIN { use_ok('Email::Filter'); }
BEGIN { use_ok('Email::Filter::Rules'); }

my $efr = Email::Filter::Rules->new( rules => '' );
ok( !$efr );

$efr = Email::Filter::Rules->new( rules => $0 );
isa_ok( $efr, 'Email::Filter::Rules' );

$efr = Email::Filter::Rules->new( rules => [ 'inbox to jbisbee', '/dev/null body Last Line' ] );
isa_ok( $efr, 'Email::Filter::Rules' );

$efr = Email::Filter::Rules->new( rules => ['inbox to'] );
isa_ok( $efr, 'Email::Filter::Rules' );

$efr = Email::Filter::Rules->new( rules => [] );
ok( !$efr, 'Fail if no rules' );

$efr = Email::Filter::Rules->new(
    rules => [ '#', 'inbox too jbisbee', '/dev/null subject Last Line' ],
    debug => 1,
);
isa_ok( $efr, 'Email::Filter::Rules' );

my $email_text = 'From: jbisbee@cpan.org' . "\n" . 'To: jbisbee@cpan.org' . "\n\n" . 'Hi';
my $email = Email::Filter->new( data => $email_text );
isa_ok( $email, 'Email::Filter' );
#diag( $efr->apply_rules($email) . 'FUCK!');
ok( !$efr->apply_rules($email), 'Did not return folder name' );

$email_text
    = 'From: jbisbee@cpan.org' . "\n"
    . 'To: jbisbee@cpan.org' . "\n"
    . 'Subject: Last Line' . "\n\n" . 'Hi';

$email = Email::Filter->new( data => $email_text );
isa_ok( $email, 'Email::Filter' );
ok( $efr->apply_rules($email), 'Return folder name' );
