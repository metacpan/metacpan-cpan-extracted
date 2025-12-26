#!/usr/bin/env perl -T

use strict;

# use Graphics::Framebuffer;
use Term::ANSIColor;
use Test::More tests => 2;

# For debugging only
# use Data::Dumper;$Data::Dumper::Sortkeys=1; $Data::Dumper::Purity=1; $Data::Dumper::Deepcopy=1;

BEGIN {
    our $VERSION = '2.01';
    use_ok('Graphics::Framebuffer');
}

diag("\r" . colored(['cyan on_black'], q{ _______        _   _              }));
diag("\r" . colored(['cyan on_black'], q{|__   __|      | | (_)             }));
diag("\r" . colored(['cyan on_black'], q{   | | ___  ___| |_ _ _ __   __ _  }));
diag("\r" . colored(['cyan on_black'], q{   | |/ _ \/ __| __| | '_ \ / _` | }));
diag("\r" . colored(['cyan on_black'], q{   | |  __/\__ \ |_| | | | | (_| | }));
diag("\r" . colored(['cyan on_black'], q{   |_|\___||___/\__|_|_| |_|\__, | }));
diag("\r" . colored(['cyan on_black'], q{                             __/ | }));
diag("\r" . colored(['cyan on_black'], q{ Graphics::Framebuffer      |___/  }));

our $F = Graphics::Framebuffer->new('RESET' => 0);
$F->graphics_mode();
isa_ok($F,'Graphics::Framebuffer');
$F->text_mode();

exit(0);
