#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

eval "use Test::CPAN::Changes 0.4; 1"
    or plan skip_all => 'Test::CPAN::Changes 0.4 required';

changes_ok();
