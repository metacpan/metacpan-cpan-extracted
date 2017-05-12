#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use EPublisher::Source::Plugin::PerltutsCom;

{ 
    package TestPublisher;
    sub new { return bless {error => ''}, shift }
    sub debug {
        my ($self,$msg) = @_;
        $self->{error} .= $msg . "\n";
    }
    sub error { shift->{error} }
}

diag "Test EPublisher::Source::Plugin::PerltutsCom $EPublisher::Source::Plugin::PerltutsCom::VERSION with $^X ($])";

my $pub            = TestPublisher->new;
my $source_options = { type => 'PerltutsCom', name => 'unicode-introduction' };
my $url_source     = EPublisher::Source::Plugin::PerltutsCom->new( $source_options );

isa_ok $url_source, 'EPublisher::Source::Plugin::PerltutsCom';

$url_source->publisher( $pub );

my @pod            = $url_source->load_source;

SKIP: {
    skip 'cannot get documentation from PerltutsCom', 1 if $pub->error =~ m{103: \s tutorial .*? does not exist}xms;
    ok $pod[0] !~ m{^=encodin}m;
}

#diag $pub->error;

done_testing();
