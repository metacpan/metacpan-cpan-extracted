#!perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 13;

BEGIN {
    use_ok('Method::ParamValidator')                                            || print "Bail out!\n";
    use_ok('Method::ParamValidator::Exception')                                 || print "Bail out!\n";
    use_ok('Method::ParamValidator::Exception::InvalidMethodName')              || print "Bail out!\n";
    use_ok('Method::ParamValidator::Exception::MissingParameters')              || print "Bail out!\n";
    use_ok('Method::ParamValidator::Exception::InvalidParameterDataStructure')  || print "Bail out!\n";
    use_ok('Method::ParamValidator::Exception::MissingRequiredParameter')       || print "Bail out!\n";
    use_ok('Method::ParamValidator::Exception::MissingMethodName')              || print "Bail out!\n";
    use_ok('Method::ParamValidator::Exception::MissingFieldName')               || print "Bail out!\n";
    use_ok('Method::ParamValidator::Exception::UndefinedRequiredParameter')     || print "Bail out!\n";
    use_ok('Method::ParamValidator::Exception::FailedParameterCheckConstraint') || print "Bail out!\n";
    use_ok('Method::ParamValidator::Key::Field')                                || print "Bail out!\n";
    use_ok('Method::ParamValidator::Key::Field::DataType')                      || print "Bail out!\n";
    use_ok('Method::ParamValidator::Key::Method')                               || print "Bail out!\n";
}

diag( "Testing Method::ParamValidator $Method::ParamValidator::VERSION, Perl $], $^X" );
