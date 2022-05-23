#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Differences;
use Test::Exception;

require Test::NoWarnings if $ENV{RELEASE_TESTING};

use Log::Any::Plugin;

use Log::Any::Test;
use Log::Any qw($log);

note 'Applying ContextStack plugin.'; {
    my @methods = qw( push_context pop_context push_scoped_context );
    ok(! $log->can($_), "No $_ method on \$log") for @methods;

    lives_ok { Log::Any::Plugin->add('ContextStack') }
        '... plugin applied ok';

    ok($log->can($_), "Now has $_ method on \$log") for @methods;
}

note 'Check push/pop'; {
    $log->clear;
    $log->push_context('foo');
    $log->debug('hello');
    $log->contains_ok(qr/^\[foo\] hello$/, '... push first context item');

    $log->push_context('bar');
    $log->debug('hello');
    $log->contains_ok(qr/^\[foo:bar\] hello$/, '... push second context item');

    $log->pop_context();
    $log->debug('hello');
    $log->contains_ok(qr/^\[foo\] hello$/, '... pop second context item');

    $log->pop_context();
    $log->debug('hello');
    $log->contains_ok(qr/^hello$/, '... pop first context item');
}

note 'Check scoped push, auto-pop'; {
    $log->clear;

    my $scope = $log->push_scoped_context('foo', 'bar');
    $log->debug('hello');
    $log->contains_ok(qr/^\[foo:bar\] hello$/, '... got context items');

    undef $scope;
    $log->debug('hello');
    $log->contains_ok(qr/^hello$/, '... context items automatically popped');
}

Test::NoWarnings::had_no_warnings() if $ENV{RELEASE_TESTING};
done_testing();
