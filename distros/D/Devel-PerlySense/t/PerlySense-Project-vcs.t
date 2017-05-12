#!/usr/bin/perl -w
use strict;

use Test::More tests => 5;
use Test::Exception;

use Data::Dumper;

use lib ("lib", "../lib");

use Devel::PerlySense::Util::Log;

use_ok("Devel::PerlySense::Project");
use_ok("Devel::PerlySense");


BEGIN { -d "t" and chdir("t"); }



ok(
    my $oPerlySense = Devel::PerlySense->new(),
    "New PerlySense object ok",
);



my $dirBase = "data/project/with-git/source";
my $dirProject = "$dirBase/bogus";

my $fileTest = "$dirProject/t/Game-Lawn.t";
ok($oPerlySense->setFindProject(file => $fileTest), "Set project ok");



my $oProject = $oPerlySense->oProject;

TODO: {
    local $TODO = "
Can't find a Git repo if it's inside a SVN  repo,
but that's perfectly ok";
    is($oProject->nameVcs, "git", "Found vcs 'git'");
}






__END__
