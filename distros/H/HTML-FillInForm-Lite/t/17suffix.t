#!perl -w

use strict;
use Test::More tests => 1;

use HTML::FillInForm::Lite qw(fillinform);

my $html = <<'EOD';
<input type="text" data-name="baz" name="foo" value="" />
EOD

like fillinform($html, { foo => "bar" }),
    qr/value="bar"/xms;

