#!/usr/bin/env perl -T

use strict;

use Graphics::Framebuffer;
use Test::More tests => 2;

# For debugging only
# use Data::Dumper;$Data::Dumper::Sortkeys=1; $Data::Dumper::Purity=1; $Data::Dumper::Deepcopy=1;

BEGIN {
    our $VERSION = '2.00';
	use_ok('Graphics::Framebuffer');
}

our $F = Graphics::Framebuffer->new('RESET' => 0);
$F->graphics_mode();
isa_ok($F,'Graphics::Framebuffer');
$F->text_mode();
