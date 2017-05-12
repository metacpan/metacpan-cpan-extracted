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
use Jedi::Launcher;
use Path::Class;

{
    local @ARGV = ( '-c', file( 't', 'configs', 'test.yml' )->stringify );
    my $jedi_launcher = Jedi::Launcher->new_with_options;

    my $config = $jedi_launcher->parse_config;
    my $jedi   = $jedi_launcher->jedi_initialize($config);
    my ( $runner, $options ) = $jedi_launcher->plack_initialize($config);

    is_deeply $config,
        {
        Jedi => {
            Roads => {
                't::lib::configs::myConfigRoot'  => '/',
                't::lib::configs::myConfigAdmin' => '/admin'
            }
        },
        Plack => {
            server => 'Starman',
            env    => 'production'
        },
        Starman => {
            workers => 2,
            port    => 9999
        },
        't::lib::configs::myConfigRoot'  => { text => 'root ok' },
        't::lib::configs::myConfigAdmin' => { text => 'admin ok' }
        },
        'config ok';

    isa_ok $jedi,   'Jedi';
    isa_ok $runner, 'Plack::Runner';

    is_deeply $options,
        [
        "--env",  "production", "--server",  "Starman",
        "--port", 9999,         "--workers", 2,
        ],
        "options is correct";

    test_psgi $jedi->start, sub {
        my $cb = shift;
        {
            my $res = $cb->( GET '/' );
            is $res->code,    200,       'status root is correct';
            is $res->content, 'root ok', '... and content is correct';
        }
        {
            my $res = $cb->( GET '/admin' );
            is $res->code,    200,        'status admin is correct';
            is $res->content, 'admin ok', '... and content is correct';
        }
    };

}

done_testing;
