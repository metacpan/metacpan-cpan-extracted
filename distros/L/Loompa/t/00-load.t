# Copyright (C) 2007 Randall Hansen
# This program is free software; you can redistribute it and/or modify it under the terms as Perl itself.
#!/usr/bin/perl -T
use strict;
use warnings;
use Data::Dumper;

use Test::More tests => 1;
use Test::Exception;

use vars qw/ $CLASS $one /;

BEGIN {
    *CLASS = \'Loompa';
    use_ok( $CLASS );
};

diag( "Testing Loompa $Loompa::VERSION, Perl $], $^X" );
