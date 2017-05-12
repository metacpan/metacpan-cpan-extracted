#!/usr/bin/perl
#
use strict;
use warnings;

use Test::More qw(no_plan);

use lib qw(t/lib);
use IkiWiki q(2.0);

use_ok( 'IkiWiki::Plugin::syntax' );

my $text = <<EOF;
#!perl -T

use Test::More;
eval "use Test::Pod 1.14";
plan skip_all => "Test::Pod 1.14 required for testing POD" if $@;
all_pod_files_ok();
EOF

#   Setting global parameters
$IkiWiki::config{syntax_engine} = q(Simple);

#   Initialize the plugin
IkiWiki::Plugin::syntax::checkconfig();

#   Check syntax highlighting from a string
my $result = IkiWiki::Plugin::syntax::preprocess( 
                language    => 'Perl',
                description => 't/pod.t',
                text        => $text );

ok($result, 'colorized perl syntax from string');

$result = IkiWiki::Plugin::syntax::preprocess(
                language    => 'Perl',
                description =>  't/pod.t',
                linenumbers =>  1,
                bars        =>  1,
                text        =>  $text );

ok($result, 'colorized perl syntax from numered string');

