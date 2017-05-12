#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 9;

BEGIN { use_ok('Email::Filter'); }
BEGIN { use_ok('Email::Filter::Rules'); }

my $rules = Email::Filter::Rules->new(
    rules => "inbox to jbisbee\n/dev/null body Last Line",
    debug => 0,
);
isa_ok( $rules, 'Email::Filter::Rules' );

my $mail_text = "From: jbisbee\@cpan.org\nTo: jbisbee\@cpan.org\n\nHi";
my $mail = Email::Filter->new( data => $mail_text );
isa_ok( $mail, 'Email::Filter' );

is( $rules->apply_rules($mail), 'inbox', 'Testing basic rule' );

my $mail_text_basic = 'From: biz@cpan.org\nTo: biz@cpan.org' . "\n\n" . 'Hi';
my $mail_basic = Email::Filter->new( data => $mail_text_basic );
isa_ok( $mail_basic, 'Email::Filter' );
isnt( $rules->apply_rules($mail_basic), 'inbox', 'Testing basic rule failure' );

my $mail_text_multiline = 'From: biz@cpan.org' . "\n"
        . 'To: biz@cpan.org' . "\n\n" . 'Hi' . "\n" . 'Bye' . "\n"
        . 'Last Line';
my $mail_multiline = Email::Filter->new( data => $mail_text_multiline );
isa_ok( $mail_multiline, 'Email::Filter' );
is( $rules->apply_rules($mail_multiline), '/dev/null', 'Testing /s for body' );
