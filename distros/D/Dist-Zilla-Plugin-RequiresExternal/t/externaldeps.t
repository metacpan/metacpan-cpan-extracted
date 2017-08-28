#!/usr/bin/env perl

use Modern::Perl '2010';    ## no critic (Modules::ProhibitUseQuotedVersion)
use Test::More 'no_plan';
use Test::Output 1.031;
use Cwd;
use Dist::Zilla::App;

my $cwd = getcwd();
chdir 't/eg';
local @ARGV = ('externaldeps');
my $stdout = stdout_from { Dist::Zilla::App->run };
chdir $cwd;

like( $stdout, qr/man/,     'man is an external prerequisite' );
like( $stdout, qr/sqlite3/, 'sqlite is an external prerequisite' );
unlike( $stdout, qr/mysql/, 'mysql isnt an external prerequisite' );
