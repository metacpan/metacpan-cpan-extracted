#!/usr/bin/env perl
# -*- cperl; cperl-indent-level: 4 -*-
# Copyright (C) 2021, Roland van Ipenburg
use strict;
use warnings;
use utf8;
use 5.014000;

use Test::More;

our $VERSION = 'v1.0.3';

use Test::Requires {
    'Test::Perl::Critic' => 0,
    'File::Basename'     => 0,
    'File::Spec'         => 0,
};
## no critic (RequireExplicitInclusion)
Test::Perl::Critic->import( '-profile' =>
      File::Spec->catfile( File::Basename::dirname(__FILE__), 'perlcriticrc', ),
);
## no critic (ProhibitCallsToUnexportedSubs)
Test::Perl::Critic::all_critic_ok(qw(Build.PL blib/ lib/ t/ xt/));
## use critic
## use critic
