#!/usr/bin/perl -w
use strict;

use Test::More tests => 4;
use Test::Exception;

use Data::Dumper;
use File::Basename;
use File::Spec::Functions;

use lib "../lib";

use_ok("Devel::PerlySense");

BEGIN { -d "t" and chdir("t"); }


ok(my $oPs = Devel::PerlySense->new(), "new ok");


my $dirData = "data/project-lib";
my $dirOrigin = "$dirData/Game";

my @aDocument = $oPs->aDocumentGrepInDir(
    dir => $dirOrigin,
    rsGrepFile => sub { 1; },
    rsGrepDocument => sub { 1 },
);
#warn Dumper([ sort map { $_->namespace } map { @{$_->oMeta->raPackage} } @aDocument ]);
is_deeply(
    [ sort map { $_->namespace } map { @{$_->oMeta->raPackage} } @aDocument ],
    [ sort qw/
              Game::Application
              Game::Controller
              Game::Direction
              Game::Event::Timed
              Game::Lawn
              Game::Location
              Game::Object
              Game::ObjectVisible
              Game::Object::WormVisible
              Game::Object::Prize
              Game::Object::Wall
              Game::Object::Worm
              Game::Object::Worm::Bot
              Game::Object::Worm::ShaiHulud
              Game::Object::Worm::Shaitan
              Game::UI
              Game::UI::None
              /],
    "aDocumentGrepInDir found all filed under dir",
);



@aDocument = $oPs->aDocumentGrepInDir(
    dir => $dirOrigin,
    rsGrepFile => sub { $_ =~ /none/i },
    rsGrepDocument => sub { 1 },
);
is_deeply(
    [ sort map { $_->namespace } map { @{$_->oMeta->raPackage} } @aDocument ],
    [ sort qw/ Game::UI::None  /],
    "aDocumentGrepInDir found all filed under dir",
);



__END__
