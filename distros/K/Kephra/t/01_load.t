#!/usr/bin/perl -w
use v5.12;
use lib 'lib';
use Test::More tests => 23;

use_ok( 'Kephra::App::Editor::SyntaxMode::Perl' );
use_ok( 'Kephra::App::Editor::SyntaxMode::No' );
use_ok( 'Kephra::App::Editor::Edit' );
use_ok( 'Kephra::App::Editor::Events' );
use_ok( 'Kephra::App::Editor::Goto' );
use_ok( 'Kephra::App::Editor::Move' );
use_ok( 'Kephra::App::Editor::Position' );
use_ok( 'Kephra::App::Editor::Property' );
use_ok( 'Kephra::App::Editor::Select' );
use_ok( 'Kephra::App::Editor::SyntaxMode' );
use_ok( 'Kephra::App::Editor::Tool' );
use_ok( 'Kephra::App::Editor::View' );
use_ok( 'Kephra::App::Editor' );
use_ok( 'Kephra::App::Dialog::About' );
use_ok( 'Kephra::App::Dialog' );
use_ok( 'Kephra::App::ReplaceBar' );
use_ok( 'Kephra::App::SearchBar' );
use_ok( 'Kephra::App::Window::Menu' );
use_ok( 'Kephra::App::Window' );
use_ok( 'Kephra::IO::LocalFile' );
use_ok( 'Kephra::Config::Default' );
use_ok( 'Kephra::Config' );
use_ok( 'Kephra' );
