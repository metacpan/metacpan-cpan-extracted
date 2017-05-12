#!/usr/bin/perl

use strict;
use warnings;

use lib 't';
use lib 'lib';

use Test::More tests => 27;
use Log::Log4perl qw(:easy);

Log::Log4perl->easy_init($WARN);

use_ok( 'Moose' ); 
require_ok( 'Moose' );


use_ok( 'RDF::Trine::Parser' );
require_ok( 'RDF::Trine::Parser' );

use_ok( 'RDF::Trine::Model' );
require_ok( 'RDF::Trine::Model' );

use_ok( 'RDF::Query' );
require_ok( 'RDF::Query' );

use_ok( 'RDF::Trine::Parser' );
require_ok( 'RDF::Trine::Parser' );

use_ok( 'RDF::Trine::Serializer' );
require_ok( 'RDF::Trine::Serializer' );

use_ok( 'JSON' );
require_ok( 'JSON' );

use_ok( 'URI::Escape' );
require_ok( 'URI::Escape' );

use_ok( 'LWP::Simple' );
require_ok( 'LWP::Simple' );


use_ok( 'RDF::NS' );
require_ok( 'RDF::NS' );


use_ok( 'UUID::Generator::PurePerl' );
require_ok( 'UUID::Generator::PurePerl' );

use_ok( 'FAIR::Profile');
use_ok('FAIR::Profile::Class');
use_ok('FAIR::Profile::Property');
use_ok('FAIR::Profile::Parser');
use_ok('FAIR::NAMESPACES');
