use strict;
use Encode;
use utf8;
use Test::More;
use Test::Exception;

use FormValidator::Nested::Filter;
use FormValidator::Nested::ProfileProvider::YAML;
use Class::Param;


my $fvtf = FormValidator::Nested::Filter->new({
    profile_provider => FormValidator::Nested::ProfileProvider::YAML->new({
        dir => 't/var/profile',
    }),
});


my $req = Class::Param->new({
    tel  => '090-6164-2010',
    tel2 => '０９０‐６１６４‐２０１０',

    start_dt_year => '2009',
    start_dt_month => '6',
    start_dt_day => '30',

    start_dt_invalid_year => '2009',
    start_dt_invalid_month => '6',
    start_dt_invalid_day => '31',

    start_dt_regex => '2009/06/30',
    start_dt_invalid_regex => '2009/06/31',
});

$req = $fvtf->filter($req, 'filter');
is $req->param('start_dt')->ymd => '2009-06-30';
ok $req->param('start_dt_invalid')->isa('FormValidator::Nested::FilterInvalid');
is $req->param('start_dt_invalid')->key => 'FormValidator::Nested::Filter::DateTime';
is $req->param('start_dt_empty') => '';

$req = $fvtf->filter($req, 'basic');

is $req->param('tel')  => '09061642010';
is $req->param('tel2') => '09061642010';


done_testing;
