#!perl
#
# This file is part of Jedi
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

{
    my $jedi = Jedi->new();
    $jedi->road( '/',      't::lib::baseroute' );
    $jedi->road( '/admin', 't::lib::baseroute' );

    test_psgi $jedi->start, sub {
        my $cb = shift;
        {
            my $res = $cb->( GET '/' );
            is $res->code,    200, 'status root is correct';
            is $res->content, '/', '... and content is correct';
        }
        {
            my $res = $cb->( GET '/admin' );
            is $res->code,    200,       'status root is correct';
            is $res->content, '/admin/', '... and content is correct';
        }
        }
}
done_testing;
