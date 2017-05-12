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
use Path::Class;

my $jedi = Jedi->new(
    config => {
        't::TestTemplate::App' =>
            { template_dir => dir( 't', 'TestTemplate' ), }
    }
);
$jedi->road( '/', 't::TestTemplate::App' );
is $jedi->config->{'t::TestTemplate::App'}{'template_dir'},
    file($0)->dir->absolute, 'config ok';

test_psgi $jedi->start, sub {
    my $cb = shift;
    {
        my $res = $cb->( GET '/' );
        is $res->code,    200,  'index ok';
        is $res->content, 'OK', '... content also';
    }
    {
        my $res = $cb->( GET '/?layout=test.tt' );
        is $res->code,    200,  'index ok';
        is $res->content, 'OK', '... content also';
    }
    {
        my $res = $cb->( GET '/?layout=main.tt' );
        is $res->code, 200, 'index ok';
        is $res->content, 'AROUND:OK:DNUORA', '... content also';
    }
    {
        my $res = $cb->( GET '/mainlayout' );
        is $res->code, 200, 'index ok';
        is $res->content, 'AROUND:OK:DNUORA', '... content also';
    }
    {
        my $res = $cb->( GET '/' );
        is $res->code, 200, 'index ok';
        is $res->content, 'AROUND:OK:DNUORA', '... content also';
    }
    {
        my $res = $cb->( GET '/error' );
        is $res->code, 500, 'error to get the template';
        like $res->content, qr{file\serror.*error.tt:\snot\sfound}x,
            '... content also';
    }

};

done_testing;
