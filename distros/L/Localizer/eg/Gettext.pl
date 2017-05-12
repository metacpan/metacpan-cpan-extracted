#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use Encode qw/encode_utf8/;
use FindBin;

use lib "$FindBin::Bin/../lib";
use Localizer::Resource;
use Localizer::Style::Gettext;

my $ja = Localizer::Resource->new(
    dictionary => +{
        'Hi, %1.' => 'やあ、%1。',
    },
    style      => Localizer::Style::Gettext->new(),
);
print encode_utf8($ja->maketext("Hi, %1.", 'John')) . "\n";
