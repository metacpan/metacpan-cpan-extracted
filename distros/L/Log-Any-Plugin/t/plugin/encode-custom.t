#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Carp qw( croak );

use Encode qw( find_encoding );

use Test::More;
use Test::Exception;

require Test::NoWarnings if $ENV{RELEASE_TESTING};

use Log::Any::Plugin;

use Log::Any::Test;
use Log::Any qw( $log );


my $msg = "鸿涛 \x{1f4A9} -- adapter with encoding set should have no warnings or errors on wide char output";
my $encoding = 'UTF-16';
my $encoder = find_encoding($encoding)
    or croak "No encoder found for encoding[$encoding]";


note 'log->error expected to be available to test functionality'; {
    $log->clear();

    ok( $log->is_error, '... $log->error is enabled' );

    $log->error("test");

    is( scalar @{$log->msgs()}, 1, "Exactly 1 error message expected to be logged" );
    $log->contains_ok("test", "message[test] expected to be logged");
}

note 'Encode has not been applied yet. Check default behaviour.'; {
    $log->clear();

    $log->error($msg);

    $log->does_not_contain_ok($encoder->encode($msg), 'no encoded message occurs');
    $log->contains_ok($msg, 'but still logged in original form');
}

note "Applying Encode plugin with custom [$encoding] encoding"; {
    lives_ok { Log::Any::Plugin->add('Encode', (encoding => 'UTF-16')) }
        'plugin applied ok';
}

note 'Check that logged message now encoded'; {
    $log->clear();

    $log->error($msg);

    $log->contains_ok($encoder->encode($msg), 'message is logged and encoded');
}


Test::NoWarnings::had_no_warnings() if $ENV{RELEASE_TESTING};
done_testing();
