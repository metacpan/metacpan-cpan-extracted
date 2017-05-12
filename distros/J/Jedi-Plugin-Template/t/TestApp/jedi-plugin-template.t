#!perl
#
# This file is part of Jedi-Plugin-Template
#
# This software is copyright (c) 2013 by celogeek <me@celogeek.com>.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use Test::Most 'die';
use HTTP::Request::Common;
use Plack::Test;
use Jedi;
use IO::Uncompress::Gunzip qw/gunzip/;
use Path::Class;

my $jedi = Jedi->new( config =>
        { 't::TestApp::App' => { template_dir => dir( 't', 'TestApp' ), } } );
$jedi->road( '/',       't::TestApp::App' );
$jedi->road( '/subdir', 't::TestApp::App' );

is $jedi->config->{'t::TestApp::App'}{'template_dir'},
    dir( 't', 'TestApp' )->absolute, 'config ok';

for my $b (qw{/ /subdir/}) {
    note "testing $b";
    test_psgi $jedi->start, sub {
        my $cb = shift;
        {
            my $res = $cb->( GET $b);
            is $res->code,    200,     'index ok';
            is $res->content, 'index', '... content also';
        }
        {
            my $res = $cb->( GET $b . 'test' );
            is $res->code,    200,         'all others ok';
            is $res->content, 'allothers', '... content also';
        }
        {
            my $res = $cb->( GET $b . 'test.js' );
            is $res->code, 200, 'public file ok';
            is $res->content, "{ 'test' : 'works !' }", 'public content ok';
            like $res->header('Content-Type'), qr{application/javascript},
                'content type is correct';
        }
        {
            my $res
                = $cb->( GET $b . 'test.js', 'ACCEPT_ENCODING' => 'gzip' );
            is $res->code, 200, 'public file ok';
            my $content      = "";
            my $pack_content = $res->content;
            gunzip \$pack_content => \$content;
            is $content, "{ 'test' : 'works !' }", 'public content ok';
            like $res->header('Content-Type'), qr{application/javascript},
                'content type is correct';
        }
        {
            my $res = $cb->( GET $b . 'sub/test.css' );
            is $res->code, 200, 'public file ok';
            is $res->content, ".a { color : red ;}", 'public content ok';
            like $res->header('Content-Type'), qr{text/css},
                'content type is correct';
        }
    };
}

done_testing;
