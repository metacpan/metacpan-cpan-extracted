#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;

BEGIN
{
    # TEST
    use_ok('Mail::LMLM');

    # TEST
    use_ok('Mail::LMLM::Render::HTML');
}

