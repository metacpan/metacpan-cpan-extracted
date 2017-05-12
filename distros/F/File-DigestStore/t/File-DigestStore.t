#!/usr/bin/env perl
use warnings;
use strict;

use lib qw( t/lib );

use File::DigestStore::Test::Ctor;
use File::DigestStore::Test::Storage;
Test::Class->runtests();
