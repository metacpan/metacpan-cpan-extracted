#!/usr/bin/perl -w

use strict;
use Test::More tests => 15;

use_ok('Maypole::Application');
use_ok('Maypole::Constants');
use_ok('Maypole::Config');
use_ok('Maypole::Headers');
use_ok('Maypole::Session');
use_ok('Maypole');
use_ok('Maypole::Model::Base');
use_ok('Maypole::Model::CDBI::Base');
use_ok('Maypole::Model::CDBI');
use_ok('Maypole::Model::CDBI::Plain');
use_ok('Maypole::Model::CDBI::FromCGI');
use_ok('Maypole::Model::CDBI::AsForm');

SKIP: {
	eval { require Data::FormValidator; };
        skip 'Data::FormValidator is not installed or does not work', 1 if ($@);
	use_ok('Maypole::Model::CDBI::DFV');
}

use_ok('Maypole::View::Base');
use_ok('Maypole::View::TT');

