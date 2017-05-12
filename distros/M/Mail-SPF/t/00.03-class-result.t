use strict;
use warnings;
use blib;

use Error ':try';

use Test::More tests => 20;

use Mail::SPF::Request;


#### Class Compilation ####

BEGIN { use_ok('Mail::SPF::Result') }


#### Basic Instantiation ####

{
    my $result = eval { Mail::SPF::Result->new('dummy server', 'dummy request', 'result text') };

    $@ eq '' and isa_ok($result, 'Mail::SPF::Result',   'Basic result object')
        or BAIL_OUT("Basic result instantiation failed: $@");

    # Have options been interpreted correctly?
    is($result->server,             'dummy server',     'Basic result server()');
    is($result->request,            'dummy request',    'Basic result request()');
    is($result->text,               'result text',      'Basic result text()');
}


#### Parameterized Result Rethrowing ####

{
    eval {
        eval { throw Mail::SPF::Result('server', 'request', 'result text') };
        $@->throw('other server', 'other request', 'other text');
    };
    my $result = $@;

    isa_ok($result,                'Mail::SPF::Result', 'Param-rethrown result object');
    is($result->server,             'other server',     'Param-rethrown result server()');
    is($result->request,            'other request',    'Param-rethrown result request()');
    is($result->text,               'other text',       'Param-rethrown result text()');
}


#### class() ####

{
    my $class;

    $class = Mail::SPF::Result->class;
    is($class,                     'Mail::SPF::Result', 'Result class()');

    $class = Mail::SPF::Result->class('PaSs');
    is($class,               'Mail::SPF::Result::Pass', 'Result class($valid_name)');

    $class = Mail::SPF::Result->class('foo');
    is($class,                      undef,              'Result class($invalid_name)');
}


#### isa_by_name(), is_code() ####

{
    my $result = Mail::SPF::Result::Pass->new('dummy server', 'dummy request');
    ok($result->isa_by_name('PaSs'),                    'Result isa_by_name($valid_name)');
    ok((not $result->isa_by_name('foo')),               'Result isa_by_name($invalid_name)');
    ok($result->is_code('PaSs'),                        'Result is_code($valid_code)');
    ok((not $result->is_code('foo')),                   'Result is_code($invalid_code)');
}


#### NeutralByDefault, code(), isa_by_name() ####

{
    my $result = Mail::SPF::Result::NeutralByDefault->new('dummy server', 'dummy request');
    isa_ok($result,       'Mail::SPF::Result::Neutral', 'NeutralByDefault result object');
    is($result->code,               'neutral',          'NeutralByDefault result code()');
    ok($result->isa_by_name('neutral-by-default'),      'NeutralByDefault isa_by_name("neutral-by-default")');
    ok($result->isa_by_name('neutral'),                 'NeutralByDefault isa_by_name("neutral")');
}
