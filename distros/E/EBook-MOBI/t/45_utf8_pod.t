#!/usr/bin/perl

use utf8;
use strict;
use warnings;

#######################
# TESTING starts here #
#######################
use Test::More tests => 1;

my $POD_in = <<'EOF';
=head2 Testing 你好

Here is some Chinese text - 你好!

=cut
EOF

# We expect the generated POD to have HTML encoded entities.

my $HTML_out = << 'EOF';
<html>
<head>
</head>
<body>
<h2>Testing &#x4F60;&#x597D;</h2>
<p>Here is some Chinese text - &#x4F60;&#x597D;!</p>
</body>
</html>
EOF

use EBook::MOBI;
my $obj = EBook::MOBI->new();
$obj->set_encoding(':encoding(UTF-8)');
$obj->add_content(data => $POD_in);
$obj->make();
my $res = $obj->print_mhtml(1);
is($res, $HTML_out, 'UTF-8 in POD parsed OK');

########
# done #
########
1;

