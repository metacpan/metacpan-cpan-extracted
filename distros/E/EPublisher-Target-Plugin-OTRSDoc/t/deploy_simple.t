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
    { path => File::Spec->catfile( $dir, 'pods', 'first.pod' ) },
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

    like_string $html, qr/<a href="http/;
    like_string $html, qr/feature-addons/;
    like_string $html, qr/>Link</;

    like_string $html, qr/<p><code class="code">/;
    like_string $html, qr/with some code/;

    like_string $html, qr/<a href="#Unittest/;
    like_string $html, qr/>Link to Unittest</;

    like_string $html, qr{<a \s+ href="
        (?:
            http://search\.cpan\.org/perldoc\? |
            https://metacpan\.org/pod/
        )
        test">Manpage</a>
    }x;
}


done_testing();

{
    package
        Mock::Publisher;

    sub new { bless {}, shift }
    sub debug { $debug = $_[1] };
}

