#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use File::Basename;
use EPublisher::Source::Plugin::Module;

my $module   = 'AnotherText';
my $inc      = dirname(__FILE__) . '/third_lib';
my $test_pod = "=pod\n\n" . slurp( $inc . '/' . $module . '.pm', 2 ) . "\n=cut\n";

my $debug = '';

{
    $debug = '';
    my $source = EPublisher::Source::Plugin::Module->new({
        name => $module,
        lib  => [$inc],
    },
        publisher => Mock::Publisher->new,
    );

    my @pods = $source->load_source;
    is_deeply \@pods, [ { pod => $test_pod, title => 'AnotherText', filename => 'AnotherText.pm' } ];
    is $debug, '';
}

{
    $debug = '';
    my $source = EPublisher::Source::Plugin::Module->new({
        name => [$module],
        lib  => [$inc],
    },
        publisher => Mock::Publisher->new,
    );

    my @pods = $source->load_source;
    is_deeply \@pods, [];
    like $debug, qr/Cannot find module/;
}

{
    $debug = '';
    my $source = EPublisher::Source::Plugin::Module->new({
        name => '/this/dir/does/not_exist',
        lib  => [$inc],
    },
        publisher => Mock::Publisher->new,
    );

    my @pods = $source->load_source;
    is_deeply \@pods, [];
    like $debug, qr/Cannot find module/;
}

{
    $debug = '';
    my $source = EPublisher::Source::Plugin::Module->new({
        name => undef,
        lib  => [$inc],
    },
        publisher => Mock::Publisher->new,
    );

    my @pods = $source->load_source;
    is_deeply \@pods, [];
    is $debug, '400: No module defined';
}

{
    $debug = '';
    my $source = EPublisher::Source::Plugin::Module->new(
        { lib => [$inc]},
        publisher => Mock::Publisher->new,
    );

    my @pods = $source->load_source( $module );
    is_deeply \@pods, [ { pod => $test_pod, title => 'AnotherText', filename => 'AnotherText.pm' } ];
    is $debug, '';
}

{
    $debug = '';
    my $source = EPublisher::Source::Plugin::Module->new(
        { title => 'test', lib => [$inc] },
        publisher => Mock::Publisher->new,
    );

    my @pods = $source->load_source( $module );
    is_deeply \@pods, [ { pod => $test_pod, title => 'test', filename => 'AnotherText.pm' } ];
    is $debug, '';
}

{
    $debug = '';
    my $source = EPublisher::Source::Plugin::Module->new(
        { title => 'pod', lib => [$inc] },
        publisher => Mock::Publisher->new,
    );

    my @pods = $source->load_source( $module );
    is_deeply \@pods, [ { pod => $test_pod, title => 'AnotherText - a test library for text output', filename => 'AnotherText.pm' } ];
    is $debug, '';
}

{
    $debug = '';
    my $source = EPublisher::Source::Plugin::Module->new(
        { title => 'pod', lib => [$inc . '/../fourth_lib' ] },
        publisher => Mock::Publisher->new,
    );

    my @pods = $source->load_source( 'Text' );
    (my $text_pod = $test_pod) =~ s{1 Another}{2 };
    is_deeply \@pods, [ { pod => $text_pod, title => '', filename => 'Text.pm' } ];
    is $debug, '';
}

done_testing();

sub slurp {
    local (@ARGV, $/) = shift;
    my $content = <>;

    my $skip = shift;
    $content =~ s{\A(?:[^\n]*\n){$skip}}{};
    
    return $content;
}

{
    package
        Mock::Publisher;

    sub new { bless {}, shift }
    sub debug { $debug = $_[1] };
}
