#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use EPublisher::Source::Plugin::MetaCPAN;

{ 
    package TestPublisher;
    sub new { return bless {error => ''}, shift }
    sub debug {
        my ($self,$msg) = @_;
        $self->{error} .= $msg . "\n";
    }
    sub error { shift->{error} }
}

diag "Test EPublisher::Source::Plugin::MetaCPAN $EPublisher::Source::Plugin::MetaCPAN::VERSION with $^X ($])";

my $pub            = TestPublisher->new;
my $source_options = { type => 'MetaCPAN', module => 'Starman' };
my $url_source     = EPublisher::Source::Plugin::MetaCPAN->new( $source_options );

isa_ok $url_source, 'EPublisher::Source::Plugin::MetaCPAN';

$url_source->publisher( $pub );

my @pod            = $url_source->load_source;

SKIP: {
    skip 'cannot get documentation from MetaCPAN', 1 if $pub->error =~ m{103: \s release .*? does not exist}xms;
    ok( ( grep{ $_->{title} =~ m{starman}xmsi }@pod ), 'starman documentation is included' );
}

#diag $pub->error;

done_testing();
