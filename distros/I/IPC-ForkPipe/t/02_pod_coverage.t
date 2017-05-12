#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
eval "use Test::Pod::Coverage 1.00";
plan skip_all => "Test::Pod::Coverage 1.00 required for testing POD coverage" if $@;

plan tests => 5;

pod_coverage_ok(
        "POEx::HTTP::Server",
        { also_private => [ qw( D new retry do_retry drop accept build_client 
                            build_server build_session build_handle close done
                            build_error error
                            prefork_child prefork_parent prefork_shutdown
                            concurrency_up concurrency_down ) ], 
        },
        "POEx::HTTP::Server, ignoring private functions",
);

pod_coverage_ok(
        "POEx::HTTP::Server::Request",
        { also_private => [ qw( DEBUG socket ) ], 
        },
        "POEx::HTTP::Server::Request, ignoring private functions",
);

pod_coverage_ok(
        "POEx::HTTP::Server::Response",
        { also_private => [ qw( DEBUG ) ], 
        },
        "POEx::HTTP::Server::Response, ignoring private functions",
);

pod_coverage_ok(
        "POEx::HTTP::Server::Connection",
        { also_private => [ qw( DEBUG aborted authtype clone fileno new user ) ], 
        },
        "POEx::HTTP::Server::Connection, ignoring private functions",
);

pod_coverage_ok(
        "POEx::HTTP::Server::Error",
        { also_private => [ qw( DEBUG details ) ], 
        },
        "POEx::HTTP::Server::Error, ignoring private functions",
);

