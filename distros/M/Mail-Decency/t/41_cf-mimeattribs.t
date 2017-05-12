#!/usr/bin/perl

use strict;
use Test::More tests => 5;
use FindBin qw/ $Bin /;
use lib "$Bin/lib";
use TestContentFilter;
use TestModule;
use TestMisc;
use YAML;

BEGIN {
    use_ok( "Mail::Decency::ContentFilter::MimeAttribs" ) or die;
}

my $content_filter = TestContentFilter::create();

my $module;
CREATE_MODULE: {
    eval {
        my $config_ref = YAML::LoadFile( "$Bin/conf/content-filter/mime-attribs.yml" );
        $module = Mail::Decency::ContentFilter::MimeAttribs->new(
            server   => $content_filter,
            name     => "Test",
            config   => $config_ref,
            database => $content_filter->database,
            cache    => $content_filter->cache,
            logger   => empty_logger()
        );
    };
    ok( !$@ && $module, "MimeAttribs loaded" ) or die( "Problem: $@" );;
};




my ( $file, $size ) = TestContentFilter::get_test_file();
$content_filter->session_init( $file, $size );

eval {
    my $res = $module->handle();
};
ok_mime_header( $file, 'X-Something', sub {
    my $ref = shift;
    return 0 if $#$ref != 0;
    chomp $ref->[0];
    return $ref->[0] eq 'Something is there';
}, "Add header X-Something" );

ok_mime_header( $file, 'Subject', sub {
    my $ref = shift;
    return 0 if $#$ref != 0;
    chomp $ref->[0];
    return $ref->[0] eq 'PREFIX: This is the Subject';
}, "Replace content in Subject" );

ok_mime_header( $file, 'X-Universally-Unique-Identifier', sub {
    my $ref = shift;
    return 1 if $#$ref != 0;
    return 0;
}, "Remove X-Universally-Unique-Identifier" );





TestMisc::cleanup( $content_filter );

