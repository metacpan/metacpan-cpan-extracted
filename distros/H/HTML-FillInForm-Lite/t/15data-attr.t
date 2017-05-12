#!perl -w

use strict;
use Test::More tests => 1;

use HTML::FillInForm::Lite qw(fillinform);

my $html = <<'EOD';
<input type="text" name="foo" value="" data-hoge="fuga" />
EOD

like fillinform($html, { foo => "bar" }),
    qr/value="bar"/xms;

