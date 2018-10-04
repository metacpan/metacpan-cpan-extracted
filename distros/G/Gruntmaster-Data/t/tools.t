#!/usr/bin/perl -w
use v5.14;

use Test::More;
use Gruntmaster::App;
use Gruntmaster::Data;
use App::Cmd::Tester;

BEGIN {
	eval {
		dbinit 'dbi:Pg:dbname=gmtest'; 1;
	} or plan skip_all => 'Cannot connect to test database. Create it by running make_test_db.sh before running this test. '. "Error: $@";
	no warnings 'redefine';
	*Gruntmaster::App::dbinit = sub {}; # Prevent reinit in Gruntmaster::App->run
	plan tests => 30;
}

sub fakein {
	open my $fakein, '<', \$_[0];
	*STDIN = $fakein;
}

sub ta {
	my ($args, $out, $err) = @_;
	my $ret = test_app 'Gruntmaster::App' => $args;
	diag 'Error: ', $ret->error if defined $ret->error;
	is $ret->output, "$out\n", join ' ', gm => @$args if defined $out;
	$ret
}

fakein <<EOF;
My cool contest
MGV
2014-01-01 00:00Z
2014-01-01 05:00Z
EOF

ta [qw/-c add ct/];

subtest 'gm -c add ct' => sub {
	plan tests => 4;
	my $ct = contest_entry 'ct';
	is $ct->{name}, 'My cool contest', 'contest name';
	is $ct->{owner}, 'MGV', 'contest owner';
	is $ct->{start}, 1388534400, 'contest start';
	is $ct->{stop}, 1388534400 + 5 * 60 * 60, 'contest stop';
};

{
	my $out = ta([qw/-c show ct/])->output;
	like $out, qr/Name: My cool contest/, 'gm -c show ct contains Name'
}

ta [qw/-c get ct owner/], 'MGV';
ta [qw/-c set ct owner nobody/];
ta [qw/-c get ct owner/], 'nobody';
ta [qw/-c list/], join "\n", sort qw/fc rc pc ct/;
ta [qw/-c rm ct/];
ok !defined contest_entry('ct'), 'gm -c rm ct';

fakein <<EOF;
Test problem
y
pc
Marius Gavrilescu
Smaranda Ciubotaru
MGV
b
gm
c
a
a
3
1
100
Ok
Ok
Ok
EOF

ta [qw/-p add pb/];

{
	my $out = ta([qw/-p show pb/])->output;
	like $out, qr/Value \(points\): 250/, 'gm -p show pb contains Value'
}

subtest 'gruntmaster-problem add' => sub {
	plan tests => 10;
	my $pb = problem_entry 'pb';
	ok $pb, 'problem exists';
	is $pb->{name}, 'Test problem', 'name';
	ok $pb->{private}, 'private';
	is $pb->{author}, 'Marius Gavrilescu', 'author';
	is $pb->{writer}, 'Smaranda Ciubotaru', 'statement writer';
	is $pb->{owner}, 'MGV', 'owner';
	is $pb->{level}, 'easy', 'level';
	is $pb->{timeout}, 1, 'time limit';
	is $pb->{olimit}, 100, 'output limit';
	ok contest_has_problem('ct', 'pb'), 'is in contest';
};

ta [qw/-p get pb author/], 'Marius Gavrilescu';
ta [qw/-p set pb owner nobody/];
ta [qw/-p get pb owner/], 'nobody';
ta [qw/-p set --file pb statement README/];
like problem_entry('pb')->{statement}, qr/Gruntmaster-Data/, 'gm -p set --file pb statement README';
ta [qw/-p list/], join "\n", sort qw/arc pca rca fca prv pb/;
ta [qw/-p rm pb/];
ok !defined problem_entry ('pb'), 'gm -p rm pb';

my $id = create_job extension => '.cpp', format => 'CPP', problem => 'arc', source => '...', owner => 'MGV';
ok abs (time - user_entry('MGV')->{lastjob}) < 2, 'create_job - lastjob looks sane';
ta [rerun => $id];
is job_entry($id)->{result}, -2, "gm rerun $id";
ta [qw/rm -j/, $id];

ta [rerun => 'fca'];
my @fca_jobs = grep { $_->{problem} eq 'fca' } @{job_list()};
ok ((!grep { $_->{result} != -2 } @fca_jobs), "gm rerun fca");

sub terr {
	my ($args, $err) = @_;
	my $ret = test_app 'Gruntmaster::App' => $args;
	like $ret->error, qr/$err/, join ' ', 'invalid:', gm => @$args;
	$ret
}

terr [qw/add/], 'No table selected';
terr [qw/-j add/], 'Don\'t know how to add to this table';
terr [qw/-c add/], 'Wrong number of arguments';
terr [qw/get/], 'No table selected';
terr [qw/-c get/], 'Wrong number of arguments';
terr [qw/list/], 'No table selected';
terr [qw/-j rerun/], 'Not enough arguments';
terr [qw/rm/], 'No table selected';
terr [qw/-j rm/], 'Wrong number of arguments';
terr [qw/set/], 'No table selected';
terr [qw/-j set 1 owner/], 'Not enough arguments';
terr [qw/-j set 1 owner x name/], 'The number of arguments must be odd';
terr [qw/show/], 'No table selected';
terr [qw/-c show/], 'Wrong number of arguments';
