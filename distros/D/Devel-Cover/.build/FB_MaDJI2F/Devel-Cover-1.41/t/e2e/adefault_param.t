#!/Users/pjcj/.plenv/versions/dc/bin/perl5.38.2

# Copyright 2002-2024, Paul Johnson (paul@pjcj.net)

# This software is free.  It is licensed under the same terms as Perl itself.

# The latest version of this software should be available from my homepage:
# http://www.pjcj.net

use strict;
use warnings;

use lib "./lib";
use lib "./blib/lib";
use lib "./blib/arch";
use lib "./t";

use Devel::Cover::Test;

my $test = Devel::Cover::Test->new("default_param");
$test->run_test;
no warnings;
$test  # for create_gold
