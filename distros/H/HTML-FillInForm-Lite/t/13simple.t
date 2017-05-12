#!perl -w

use strict;
use Test::More tests => 4;

use HTML::FillInForm::Lite qw(fillinform);

my $html = <<'EOD';
<input type="text" name="foo" value="" />
EOD

like fillinform($html, { foo => "bar" }),
    qr/value="bar"/xms;

like fillinform($html, { foo => "baz" }),
    qr/value="baz"/xms;

my $fif = fillinform({ foo => "bar" });
like $fif->($html),
    qr/value="bar"/xms for 1 .. 2;

