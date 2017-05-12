#!/usr/bin/perl

use strict;
use warnings;
use FindBin;

use lib "$FindBin::Bin/../../lib";

use JSORB;
use JSORB::Server::Simple;
use JSORB::Dispatcher::Path;
use JSORB::Client::Compiler::Javascript;

my $namespace = JSORB::Namespace->new(
    name     => 'Math',
    elements => [
        JSORB::Interface->new(
            name       => 'Simple',
            procedures => [
                JSORB::Procedure->new(
                    name  => 'add',
                    body  => sub { $_[0] + $_[0] },
                    spec  => [ 'Int' => 'Int' => 'Int' ],
                )
            ]
        )
    ]
);

JSORB::Client::Compiler::Javascript->new->compile(
    namespace => $namespace,
    to        => [ $FindBin::Bin, 'MathSimple.js' ]
);

JSORB::Server::Simple->new_with_traits(
    port       => 9999,
    dispatcher => JSORB::Dispatcher::Path->new(
        namespace => $namespace
    )
)->run;