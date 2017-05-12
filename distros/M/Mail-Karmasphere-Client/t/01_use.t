use strict;
use warnings;
use blib;

use Test::More tests => 18;

use_ok('Mail::Karmasphere::Client');
use_ok('Mail::Karmasphere::Query');
use_ok('Mail::Karmasphere::Response');

use_ok('Mail::Karmasphere::Publisher');
use_ok('Mail::Karmasphere::Parser::Simple::List');       # base class, no further tests
use_ok('Mail::Karmasphere::Parser::Simple::IPList');
use_ok('Mail::Karmasphere::Parser::Simple::URLList');
use_ok('Mail::Karmasphere::Parser::Simple::DomainList');
use_ok('Mail::Karmasphere::Parser::Simple::EmailList');

use_ok('Mail::Karmasphere::Parser::RBL::Base');      # base class, no further tests
use_ok('Mail::Karmasphere::Parser::RBL::Mixed');     # full tests in 10_rbl_mixed.t
use_ok('Mail::Karmasphere::Parser::RBL::SimpleIP');  # full tests in
use_ok('Mail::Karmasphere::Parser::RBL::URL');       # full tests in
use_ok('Mail::Karmasphere::Parser::RBL::Domain');    # full tests in

use_ok('Mail::Karmasphere::Parser::Score::IP4');     # full tests in
use_ok('Mail::Karmasphere::Parser::Score::Domain');  # full tests in
use_ok('Mail::Karmasphere::Parser::Score::Email');   # full tests in
use_ok('Mail::Karmasphere::Parser::Score::URL');     # full tests in

