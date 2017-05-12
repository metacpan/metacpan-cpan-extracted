#!/usr/bin/env perl

use strict;
use warnings;

use HTML::Restrict;
use LWP::ConsoleLogger::Easy qw( debug_ua );
use WWW::Mechanize;

my $mech  = WWW::Mechanize->new;
my $debug = debug_ua($mech);

$debug->text_pre_filter( sub { return shift } );
$debug->dump_content(0);
$debug->dump_cookies(0);
$debug->dump_params(0);

my $hr = HTML::Restrict->new(
    rules => { link => [ 'href', 'rel', 'title', 'type' ], } );

$debug->html_restrict($hr);

$mech->get('https://metacpan.org');

=pod

Set your own HTML::Restrict object if you'd like to allow some HTML to appear
in your text.

=cut
