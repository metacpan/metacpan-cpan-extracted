#!/usr/bin/perl
# $Id: 01-use.t 2 2006-05-02 11:15:26Z roel $
use strict;
use warnings;
use Test::More tests => 2;
use lib 'lib';

BEGIN { use_ok('FrameMaker::MifTree') };

is($FrameMaker::MifTree::VERSION, 0.075);

__END__
