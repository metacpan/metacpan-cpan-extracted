#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Warn;

use MVC::Neaf;

warnings_like {
    get '/' => sub { }, view => 'TT';
} [{carped => qr#view.*deprecated.*-view#} ], "Deprecated, alternative suggested
";

done_testing;
