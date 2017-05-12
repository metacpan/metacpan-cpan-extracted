use warnings;
use strict;
use Test::More 'no_plan';
use lib qw (lib ../lib);
use MKDoc::Text::Structured;

my $text = <<EOF;
This is *strong text*

*I* am *here*.
EOF

my $res = MKDoc::Text::Structured::process ($text);
like ($res, qr#<p>This is <strong>strong text</strong></p>#);
like ($res, qr#<strong>I</strong>#);
like ($res, qr#<strong>here</strong>#);

1;

__END__
