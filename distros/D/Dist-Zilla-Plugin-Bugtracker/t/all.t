#!/usr/bin/env perl
use warnings;
use strict;
use Dist::Zilla::Plugin::Bugtracker;
use Test::More tests => 5;
use Test::MockObject;
use Test::Differences;

sub test_plugin {
    my ($args, $web, $mailto) = @_;
    my $expect = {};
    $expect->{resources}{bugtracker}{web}    = $web    if defined $web;
    $expect->{resources}{bugtracker}{mailto} = $mailto if defined $mailto;
    my $mock_zilla = Test::MockObject->new;
    $mock_zilla->set_isa('Dist::Zilla');
    $mock_zilla->mock(name => sub { 'Foo-Bar' });
    my $o = Dist::Zilla::Plugin::Bugtracker->new(
        plugin_name => 'Bugtracker',
        zilla       => $mock_zilla,
        %$args,
    );
    eq_or_diff $o->metadata, $expect, 'metadata';
}
test_plugin(
    {},
    'http://rt.cpan.org/Public/Dist/Display.html?Name=Foo-Bar',
    'bug-foo-bar at rt.cpan.org'
);
test_plugin({ web => 'http://github.com/me/%s/issues', },
    'http://github.com/me/Foo-Bar/issues', undef);
test_plugin(
    { mailto => 'me-%U@example.org' },
    'http://rt.cpan.org/Public/Dist/Display.html?Name=Foo-Bar',
    'me-FOO-BAR@example.org'
);
test_plugin(
    { web => 'http://github.com/me/p5-%l/issues', mailto => 'me@example.org' },
    'http://github.com/me/p5-foo-bar/issues', 'me@example.org'
);
test_plugin({ mailto => '' },
    'http://rt.cpan.org/Public/Dist/Display.html?Name=Foo-Bar');
