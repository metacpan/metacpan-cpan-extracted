#!/usr/bin/perl -w

use strict;
use Test::More 'no_plan';
$| = 1;



# =begin test setup
BEGIN {
    use File::Basename;
    use lib dirname($0).'/../lib';

    use InlineTest;
    use Clone::Any qw( clone );
    use Scalar::Util qw(refaddr);

    use_ok('JIRA::REST::Class::Mixins');
    use_ok('JIRA::REST::Class::Factory');
    use_ok('JIRA::REST::Class::FactoryTypes', qw( %TYPES ));
}



# =begin test setup
sub get_factory {
    JIRA::REST::Class::Mixins->factory(InlineTest->constructor_args);
}



# =begin testing constructor 3
$::__tc = Test::Builder->new->current_test;
{
my $jira = JIRA::REST::Class::Mixins->jira(InlineTest->constructor_args);
isa_ok($jira, $TYPES{class}, 'Mixins->jira');
isa_ok($jira->JIRA_REST, 'JIRA::REST', 'JIRA::REST::Class->JIRA_REST');
isa_ok($jira->REST_CLIENT, 'REST::Client', 'JIRA::REST::Class->REST_CLIENT');
}
is( Test::Builder->new->current_test - $::__tc, 3,
	'3 tests were run in the section' );



# =begin testing factory 2
$::__tc = Test::Builder->new->current_test;
{
my $factory = get_factory();
isa_ok($factory, $TYPES{factory}, 'Mixins->factory');
ok(JIRA::REST::Class::Mixins->obj_isa($factory, 'factory'),
   'Mixins->obj_isa works');
}
is( Test::Builder->new->current_test - $::__tc, 2,
	'2 tests were run in the section' );



# =begin testing cosmetic_copy 3
$::__tc = Test::Builder->new->current_test;
{
my @PROJ = InlineTest->project_data;
my $orig = [ @PROJ ];
my $copy = JIRA::REST::Class::Mixins->cosmetic_copy($orig);

is_deeply( $orig, $copy, "simple cosmetic copy has same content as original" );

cmp_ok( refaddr($orig), 'ne', refaddr($copy),
        "simple cosmetic copy has different address as original" );

# make a complex reference to copy
my $factory = get_factory();
$orig = [ map { $factory->make_object('project', { data => $_ }) } @PROJ ];
$copy = JIRA::REST::Class::Mixins->cosmetic_copy($orig);

is_deeply( $copy, [
  "JIRA::REST::Class::Project->name(JIRA::REST::Class)",
  "JIRA::REST::Class::Project->name(Kanban software development sample project)",
  "JIRA::REST::Class::Project->name(PacKay Productions)",
  "JIRA::REST::Class::Project->name(Project Management Sample Project)",
  "JIRA::REST::Class::Project->name(Scrum Software Development Sample Project)"
], "complex cosmetic copy is properly serialized");
}
is( Test::Builder->new->current_test - $::__tc, 3,
	'3 tests were run in the section' );



# =begin testing _get_known_args 5
$::__tc = Test::Builder->new->current_test;
{
package InlineTestMixins;
use Test::Exception;
use Test::More;

sub test_too_many_args {
    JIRA::REST::Class::Mixins->_get_known_args(
        [ qw/ url username password rest_client_config proxy
              ssl_verify_none anonymous unknown1 unknown2 / ],
        qw/ url username password rest_client_config proxy
            ssl_verify_none anonymous/
    );
}

# also excercizes __subname()

throws_ok( sub { test_too_many_args() },
           qr/^InlineTestMixins->test_too_many_args:/,
           '_get_known_args constructs caller string okay' );

throws_ok( sub { test_too_many_args() },
           qr/too many arguments/,
           '_get_known_args catches too many args okay' );

sub test_unknown_args {
    JIRA::REST::Class::Mixins->_get_known_args(
        [ { map { $_ => $_ } qw/ url username password
                                rest_client_config proxy
                                ssl_verify_none anonymous
                                unknown1 unknown2 / } ],
        qw/ url username password rest_client_config proxy
            ssl_verify_none anonymous /
    );
}

# also excercizes _quoted_list()

throws_ok( sub { test_unknown_args() },
           qr/unknown arguments - 'unknown1', 'unknown2'/,
           '_get_known_args catches unknown args okay' );

my %expected = (
    map { $_ => $_ } qw/ url username password
                         rest_client_config proxy
                         ssl_verify_none anonymous /
);

sub test_positional_args {
    JIRA::REST::Class::Mixins->_get_known_args(
        [ qw/ url username password rest_client_config proxy
              ssl_verify_none anonymous / ],
        qw/ url username password rest_client_config proxy
            ssl_verify_none anonymous /
    );
}

is_deeply( test_positional_args(), \%expected,
           '_get_known_args processes positional args okay' );

sub test_named_args {
    JIRA::REST::Class::Mixins->_get_known_args(
        [ { map { $_ => $_ } qw/ url username password
                                rest_client_config proxy
                                ssl_verify_none anonymous / } ],
        qw/ url username password rest_client_config proxy
            ssl_verify_none anonymous /
    );
}

is_deeply( test_named_args(), \%expected,
           '_get_known_args processes named args okay' );
}
is( Test::Builder->new->current_test - $::__tc, 5,
	'5 tests were run in the section' );



# =begin testing _check_required_args 1
$::__tc = Test::Builder->new->current_test;
{
use Test::Exception;
use Test::More;

sub test_missing_req_args {
    my %args = map { $_ => $_ } qw/ username password /;
    JIRA::REST::Class::Mixins->_check_required_args(
        \%args,
        url  => "you must specify a URL to connect to",
    );
}

throws_ok( sub { test_missing_req_args() },
           qr/you must specify a URL to connect to/,
           '_check_required_args identifies missing args okay' );
}
is( Test::Builder->new->current_test - $::__tc, 1,
	'1 test was run in the section' );



# =begin testing _croakmsg 2
$::__tc = Test::Builder->new->current_test;
{
package InlineTestMixins;
use Test::More;

sub test_croakmsg_noargs {
    JIRA::REST::Class::Mixins->_croakmsg("I died");
}

# also excercizes __subname()

is( test_croakmsg_noargs(),
    'InlineTestMixins->test_croakmsg_noargs: I died',
    '_croakmsg constructs no argument string okay' );

sub test_croakmsg_args {
    JIRA::REST::Class::Mixins->_croakmsg("I died", qw/ arg1 arg2 /);
}

is( test_croakmsg_args(),
    'InlineTestMixins->test_croakmsg_args(arg1, arg2): I died',
    '_croakmsg constructs argument string okay' );
}
is( Test::Builder->new->current_test - $::__tc, 2,
	'2 tests were run in the section' );




1;
