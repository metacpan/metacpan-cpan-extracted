#!/usr/local/bin/perl
use strict;
use Gungho;

Gungho->run(
    {
        provider   => sub {
            
        },
        components => [
            qw(+GunghoX::FollowLinks)
        ]
    }
);