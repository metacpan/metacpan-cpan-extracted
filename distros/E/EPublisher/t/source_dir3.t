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
        subdirs => 1,
    },
        publisher => Mock::Publisher->new,
    );

    my @pods = $source->load_source;
    is_deeply \@pods, [ { pod => $test_pod, title => 'Test.pod', filename => 'Test.pod' } ];
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
