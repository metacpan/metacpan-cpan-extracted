#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use File::Basename;
use EPublisher::Source::Plugin::File;

my $file     = dirname(__FILE__) . '/pods/Test.pod';
my $test_pod = "=pod\n\n" . slurp( $file );

my $debug = '';

{
    $debug = '';
    my $source = EPublisher::Source::Plugin::File->new({
        path => $file,
    },
        publisher => Mock::Publisher->new,
    );

    my @pods = $source->load_source;
    is_deeply \@pods, [ { pod => $test_pod, title => 'Test.pod', filename => 'Test.pod' } ];
    is $debug, '';
}

{
    $debug = '';
    my $source = EPublisher::Source::Plugin::File->new({
        path => [$file],
    },
        publisher => Mock::Publisher->new,
    );

    my @pods = $source->load_source;
    is_deeply \@pods, [];
    like $debug, qr/is not a file/;
}

{
    $debug = '';
    my $source = EPublisher::Source::Plugin::File->new({
        path => '/this/dir/does/not_exist',
    },
        publisher => Mock::Publisher->new,
    );

    my @pods = $source->load_source;
    is_deeply \@pods, [];
    like $debug, qr/is not a file/;
}

{
    $debug = '';
    my $source = EPublisher::Source::Plugin::File->new({
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
    my $source = EPublisher::Source::Plugin::File->new({
        path => [undef],
    },
        publisher => Mock::Publisher->new,
    );

    my @pods = $source->load_source;
    is_deeply \@pods, [];
    like $debug, qr/is not a file/;
}

{
    $debug = '';
    my $source = EPublisher::Source::Plugin::File->new(
        {},
        publisher => Mock::Publisher->new,
    );

    my @pods = $source->load_source( $file );
    is_deeply \@pods, [ { pod => $test_pod, title => 'Test.pod', filename => 'Test.pod' } ];
    is $debug, '';
}

{
    $debug = '';
    my $source = EPublisher::Source::Plugin::File->new(
        { title => 'test' },
        publisher => Mock::Publisher->new,
    );

    my @pods = $source->load_source( $file );
    is_deeply \@pods, [ { pod => $test_pod, title => 'test', filename => 'Test.pod' } ];
    is $debug, '';
}

{
    $debug = '';
    my $source = EPublisher::Source::Plugin::File->new(
        { title => 'pod' },
        publisher => Mock::Publisher->new,
    );

    my @pods = $source->load_source( $file );
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
