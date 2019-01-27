#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use File::Basename;
use EPublisher::Source::Plugin::Dir;

my $dir      = dirname(__FILE__) . '/pods';
my $test_pod = "=pod\n\n" . slurp( $dir . '/Test.pod' );

my $debug = '';

{
    $debug = '';
    my $source = EPublisher::Source::Plugin::Dir->new({
        path => $dir,
    },
        publisher => Mock::Publisher->new,
    );

    my @pods = $source->load_source;
    is_deeply \@pods, [ { pod => $test_pod, title => 'Test.pod', filename => 'Test.pod' } ];
    is $debug, '';
}

{
    $debug = '';
    my $source = EPublisher::Source::Plugin::Dir->new({
        path => [$dir],
    },
        publisher => Mock::Publisher->new,
    );

    my @pods = $source->load_source;
    is_deeply \@pods, [ { pod => $test_pod, title => 'Test.pod', filename => 'Test.pod' } ];
    is $debug, '';
}

{
    $debug = '';
    my $source = EPublisher::Source::Plugin::Dir->new({
        path => '/this/dir/does/not_exist',
    },
        publisher => Mock::Publisher->new,
    );

    my @pods = $source->load_source;
    is_deeply \@pods, [];
    is $debug, '400: /this/dir/does/not_exist does not exist';
}

{
    $debug = '';
    my $source = EPublisher::Source::Plugin::Dir->new({
        path => undef,
    },
        publisher => Mock::Publisher->new,
    );

    my @pods = $source->load_source;
    is_deeply \@pods, [];
    is $debug, '400: No path given';
}

{
    $debug = '';
    my $source = EPublisher::Source::Plugin::Dir->new({
        path => [undef],
    },
        publisher => Mock::Publisher->new,
    );

    my @pods = $source->load_source;
    is_deeply \@pods, [];
    is $debug, '400: undefined path given';
}

{
    $debug = '';
    my $source = EPublisher::Source::Plugin::Dir->new({
        path => $dir,
        exclude => 't/pods/Test.pod',
    },
        publisher => Mock::Publisher->new,
    );

    my @pods = $source->load_source;
    is_deeply \@pods, [];
    is $debug, '';
}

{
    $debug = '';
    my $source = EPublisher::Source::Plugin::Dir->new({
        path => $dir,
        exclude => ['t/pods/Test.pod'],
    },
        publisher => Mock::Publisher->new,
    );

    my @pods = $source->load_source;
    is_deeply \@pods, [];
    is $debug, '';
}

{
    $debug = '';
    my $source = EPublisher::Source::Plugin::Dir->new(
        {},
        publisher => Mock::Publisher->new,
    );

    my @pods = $source->load_source( $dir );
    is_deeply \@pods, [ { pod => $test_pod, title => 'Test.pod', filename => 'Test.pod' } ];
    is $debug, '';
}

{
    $debug = '';
    my $source = EPublisher::Source::Plugin::Dir->new(
        { title => 'test' },
        publisher => Mock::Publisher->new,
    );

    my @pods = $source->load_source( $dir );
    is_deeply \@pods, [ { pod => $test_pod, title => 'test', filename => 'Test.pod' } ];
    is $debug, '';
}

{
    $debug = '';
    my $source = EPublisher::Source::Plugin::Dir->new(
        { title => 'pod' },
        publisher => Mock::Publisher->new,
    );

    my @pods = $source->load_source( $dir );
    is_deeply \@pods, [ { pod => $test_pod, title => 'TEST', filename => 'Test.pod' } ];
    is $debug, '';
}

done_testing();

sub slurp {
    local (@ARGV, $/) = shift;
    <>;
}

{
    package
        Mock::Publisher;

    sub new { bless {}, shift }
    sub debug { $debug = $_[1] };
}
