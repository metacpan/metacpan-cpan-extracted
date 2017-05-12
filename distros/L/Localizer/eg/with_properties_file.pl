#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use feature qw/say/;
use FindBin;
use Localizer::Resource;
use Localizer::Style::Gettext;
use Config::Properties;

my $ja = Localizer::Resource->new(
    dictionary => +{ Config::Properties->new(
            file => "$FindBin::Bin/ja.properties"
        )->properties },
    format => Localizer::Style::Gettext->new(),
    functions => {
        dubbil => sub { return $_[0] * 2 },
    },
);
say $ja->maketext("Hi, %1.", "John");
say $ja->maketext("Double: %dubbil(%1)", 7);
