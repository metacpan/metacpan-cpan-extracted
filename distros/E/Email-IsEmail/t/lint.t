#!/usr/bin/env perl

use Test::Perl::Critic ( -exclude => [ 'OTRS', 'ProhibitAccessOfPrivateData' ] );


all_critic_ok('lib');
