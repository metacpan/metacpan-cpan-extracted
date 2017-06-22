#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

use_ok('Group::Git');
use_ok('Group::Git::Bitbucket');
use_ok('Group::Git::Github');
use_ok('Group::Git::Gitosis');
use_ok('Group::Git::Stash');
use_ok('Group::Git::Repo');
use_ok('Group::Git::Taggers');
use_ok('Group::Git::Taggers::Local');
use_ok('Group::Git::Taggers::Remote');
use_ok('Group::Git::Cmd::Branch');
use_ok('Group::Git::Cmd::Help');
use_ok('Group::Git::Cmd::List');
use_ok('Group::Git::Cmd::Pull');
use_ok('Group::Git::Cmd::Sh');
use_ok('Group::Git::Cmd::State');
use_ok('Group::Git::Cmd::Status');
use_ok('Group::Git::Cmd::TagList');
use_ok('Group::Git::Cmd::Watch');

diag( "Testing Group::Git $Group::Git::VERSION, Perl $], $^X" );
done_testing();
