#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

require Test::NoWarnings if $ENV{RELEASE_TESTING};


note 'get_class_name'; {

    use Log::Any::Plugin::Util qw( get_class_name );

    is(get_class_name('MyClass'), 'Log::Any::Plugin::MyClass',
        '... short names get prefix');
    is(get_class_name('+MyNamespace::MyClass'), 'MyNamespace::MyClass',
        '... full names get preserved');
}

Test::NoWarnings::had_no_warnings() if $ENV{RELEASE_TESTING};
done_testing();
