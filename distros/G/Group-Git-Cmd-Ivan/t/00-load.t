#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

use_ok('Group::Git::Cmd::Tag');
use_ok('Group::Git::Cmd::Ivan');
use_ok('Group::Git::Cmd::Build');

diag( "Testing Group::Git::Cmd::Ivan $Group::Git::Cmd::Ivan::VERSION, Perl $], $^X" );
done_testing();
