#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::LongString;
use Capture::Tiny qw(capture_stdout);

use File::Basename;
use File::Spec;
use EPublisher::Source::Plugin::File;
use EPublisher::Target::Plugin::OTRSDoc;

my $debug     = '';
my $publisher = Mock::Publisher->new;

my $dir    = dirname __FILE__;
my $source = EPublisher::Source::Plugin::File->new(
    { path => File::Spec->catfile( $dir, 'pods', 'empty_link.pod' ) },
    publisher => $publisher,
);

my @pods = $source->load_source;

{
    my $target = EPublisher::Target::Plugin::OTRSDoc->new(
        { source => \@pods },
        publisher => $publisher,
    );

    my $html = capture_stdout {
        $target->deploy;
    };

    like_string $html, qr/<h1 id="Unittest">Unittest/;

    like_string $html, qr/POD ERROR/;
}


done_testing();

{
    package
        Mock::Publisher;

    sub new { bless {}, shift }
    sub debug { $debug = $_[1] };
}

