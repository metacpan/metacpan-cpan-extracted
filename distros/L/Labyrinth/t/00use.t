#!/usr/bin/perl -w
use strict;

use Test::More tests => 30;

BEGIN {
	use_ok('Labyrinth');
	use_ok('Labyrinth::Audit');
	use_ok('Labyrinth::Constraints');
	use_ok('Labyrinth::Constraints::Emails');
	use_ok('Labyrinth::CookieLib');
	use_ok('Labyrinth::DBUtils');
	use_ok('Labyrinth::DIUtils');
	use_ok('Labyrinth::DIUtils::Base');
	use_ok('Labyrinth::DTUtils');
	use_ok('Labyrinth::Globals');
	use_ok('Labyrinth::Groups');
	use_ok('Labyrinth::IPAddr');
	use_ok('Labyrinth::Inbox');
	use_ok('Labyrinth::MLUtils');
	use_ok('Labyrinth::Mailer');
	use_ok('Labyrinth::Media');
	use_ok('Labyrinth::Metadata');
	use_ok('Labyrinth::Phrasebook');
	use_ok('Labyrinth::Plugin::Base');
	use_ok('Labyrinth::Plugins');
	use_ok('Labyrinth::Query::CGI');
	use_ok('Labyrinth::RSS');
	use_ok('Labyrinth::Request');
	use_ok('Labyrinth::Session');
	use_ok('Labyrinth::Support');
	use_ok('Labyrinth::Users');
	use_ok('Labyrinth::Variables');
	use_ok('Labyrinth::Writer');
	use_ok('Labyrinth::Writer::Parser::TT');
	use_ok('Labyrinth::Writer::Render::CGI');
}
