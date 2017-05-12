#!/usr/bin/perl -w
use strict;

use Test::More tests => 11;
use Test::Exception;

use File::Basename;
use File::Spec::Functions;
use Data::Dumper;

use lib "../lib";

use_ok("Devel::PerlySense");
use_ok("Devel::PerlySense::Document::Location");


BEGIN { -d "t" and chdir("t"); }


ok(my $oPs = Devel::PerlySense->new(), "new ok");



my $dirData = "data/project-lib";
my $fileOrigin = "$dirData/Game/Application.pm";
my $rexFileDest = qr/Game.Object.Worm.Bot.pm/;
my $text;
my $oLocation;
my $rex;


$text = q{METHODS
  new([$left = 11], [$top = 12], [$direction = "left"], [$length = 3)
    Create new Bot Worm, facing in $direction ("left", "right", "up", "down"
    (only left supported right now)), with a body a total size of $length.};
ok($oLocation = $oPs->oLocationSmartDoc(file => $fileOrigin, row => 115, col => 45), "Found POD ok");
is($oLocation->rhProperty->{text}, $text, " Found POD text ok");
like($oLocation->file, $rexFileDest, " In correct file");
is($oLocation->row, 74, " row");
is($oLocation->col, 1, " col");
is($oLocation->rhProperty->{docType}, "hint", " docType method");
is($oLocation->rhProperty->{found}, "method", " docType method");
is($oLocation->rhProperty->{name}, "new", " name");




__END__
