#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use File::Basename;
use EPublisher::Source::Plugin::Dir;

my $dir      = dirname(__FILE__);
my $test_pod = "=pod\n\nThis is a test\n\n=cut";
my $pod_two  = q~=pod

=head1 NAME

08_extract_pod.t - Unit test file for PPI utility module

=head2 AUTHOR

Au. Thor

=cut
~;

my $debug = '';

{
    my $source = EPublisher::Source::Plugin::Dir->new(
        { title => 'pod', subdirs => 0, testfiles => 1 },
        publisher => Mock::Publisher->new,
    );

    my @pods = $source->load_source( $dir );
    is_deeply \@pods, [
        { pod => "=pod\n\n=head1 A unit test\n\n=cut\n", title => 'A unit test', filename => '03_base_source.t' },
        { pod => "=pod\n\n05_sources.t - test for the source plugins\n\n=cut\n", title => '', filename => '05_sources.t' },
        { pod => $pod_two, title => 'NAME', filename => '08_extract_pod.t' },
        { pod => "=pod\n\n05_sources.t - test for the source plugins\n\n=cut\n", title => '', filename => '09_source_file.t' },
        { pod => "=pod\n\n=head1 Testcase\n\n05_sources.t - test for the source plugins\n\n=cut\n", title => 'Testcase', filename => '10_source_file_title_pod.t' },
        { pod => "=pod\n\n=head1 Testcase\n\n05_sources.t - test for the source plugins\n\n=cut\n", title => 'Testcase', filename => '12_source_file_arbitrary_title.t' },
        { pod => "=pod\n\nThis is a test\n\n=cut\n", title => '', filename => 'source_dir2.t' },
    ];
    is $debug, '';
}

done_testing();

{
    package
        Mock::Publisher;

    sub new { bless {}, shift }
    sub debug { $debug = $_[1] };
}

=pod

This is a test

=cut
