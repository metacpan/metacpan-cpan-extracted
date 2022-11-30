#!/usr/bin/perl -w
use v5.12;
use lib 'lib';
use Test::More tests => 15;

use_ok( 'Kephra::App::Editor::Edit' );
use_ok( 'Kephra::App::Editor::Move' );
use_ok( 'Kephra::App::Editor::Position' );
use_ok( 'Kephra::App::Editor::Select' );
use_ok( 'Kephra::App::Editor::SyntaxMode' );
use_ok( 'Kephra::App::Editor::Tool' );
use_ok( 'Kephra::App::Editor' );
use_ok( 'Kephra::App::Dialog::About' );
use_ok( 'Kephra::App::Dialog' );
use_ok( 'Kephra::App::ReplaceBar' );
use_ok( 'Kephra::App::SearchBar' );
use_ok( 'Kephra::App::Window::Menu' );
use_ok( 'Kephra::App::Window' );
use_ok( 'Kephra::IO::LocalFile' );
use_ok( 'Kephra' );
