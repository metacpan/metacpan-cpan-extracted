#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use_ok '{{ $dist->name =~ s/-/::/gr }}';

done_testing;
