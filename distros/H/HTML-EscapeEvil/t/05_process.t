
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl HTML-EscapeEvil.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 3;
use strict;
use warnings;

use HTML::EscapeEvil;

my($escapeevil,$html);

$html = <<HTML;
<html>
<head>
<title>test</title>
</head>

<body>
<? PI ?>
hello
<a href="hello.html">a</a>
</body>
</html>
HTML


$escapeevil = HTML::EscapeEvil->new;
$escapeevil->allow_process(1);
$escapeevil->collection_process(1);

# ==================================================== #
# 1 - 3
# Process Check
# ==================================================== #
ok($escapeevil->allow_process);
ok($escapeevil->collection_process);

$escapeevil->parse($html);
ok(scalar @{$escapeevil->processes});

$escapeevil->clear;
