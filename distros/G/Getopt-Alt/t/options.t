#!/usr/bin/perl

use strict;
use warnings;
use List::Util qw/sum/;
use Test::More;
use Test::Warnings;
use Getopt::Alt::Option;

option_type();
option_process();
done_testing();

sub option_type {
    my $class_name = 'Getopt::Alt::Dynamic::Test';
    my $object = Moose::Meta::Class->create(
        $class_name,
        superclasses => [ 'Getopt::Alt::Dynamic' ],
    );

    my $opt = build_option($object, ['one|o']);
    ok $opt, "Create opt from array";

    $opt = build_option($object, 'two|t');
    ok $opt, "Create opt from string";

    $opt = build_option($object, {
        name  => 'three',
        names => [qw/ three T /],
        opt   => 'three|T',
    });
    ok $opt, "Create opt from hash";

    $opt = build_option(
        $object,
        name  => 'three',
        names => [qw/ three T /],
        opt   => 'three|T',
    );
    ok $opt, "Create opt from hash";

    $opt = build_option($object, 'four|f=d');
    ok $opt, "Create opt for a digit";

    eval { build_option($object, sub {'four'}) };
    ok $@, "Bad reference";

    eval { build_option($object, 'five|f@') };
    ok $@, "Bad reference";

    # bad spec
    eval { build_option($object, '|') };
    ok $@, "Bad spec";

    # bad spec
    eval { build_option($object, 'a||q') };
    ok $@, "Bad spec";
}

sub option_process {
    my $class_name = 'Getopt::Alt::Dynamic::Test';
    my $object = Moose::Meta::Class->create(
        $class_name,
        superclasses => [ 'Getopt::Alt::Dynamic' ],
    );

    my $one = build_option($object, ['one|o!']);
    my ($value, $used) = $one->process('one', '', undef, []);
    is $value, 1, '--long sets value to 1';
    ($value, $used) = $one->process('no-one', '', undef, []);
    is $value, 0, '--no-one long sets value to 0';

    my $two = build_option($object, ['two|t+']);
    ($value, $used) = $two->process('', 't', undef, []);
    is $value, 1, '--short sets value to 1';
    ($value, $used) = $two->process('', 't', undef, []);
    is $value, 2, '--short again sets value to 2';

    my $three = build_option($object, ['three|T=s']);
    eval { $three->process('', 'T', undef, []) };
    my $error = $@;
    ok ref $error, 'Get an error';
    is $error->[0]->message, "The option '-T' requires an Str argument\n";

    eval { $three->process('', 'T', '', []) };
    $error = $@;
    ok ref $error, 'Get an error';
    is $error->[0]->message, "The option '-T' requires an Str argument\n";

    ($value, $used) = $three->process('', 'T', 'test', []);
    is $value, 'test', '--short again sets value to test';

    $three->{type} = 'Other';
    eval { $three->process('', 'T', 'O', []) };
    $error = $@;
    ok $error, 'Get an error';
    like $error, qr/^Unknown type 'Other'\n/, 'Error on unknown types';
}
