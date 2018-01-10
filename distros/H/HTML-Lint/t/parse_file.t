#!perl -T

use warnings;
use strict;

use Test::More tests => 1;
use HTML::Lint;
use File::Temp qw( tempfile );

my ($o, $OUTPUT_FN) = tempfile( SUFFIX => '.xhtml', UNLINK => 1);
print {$o} <<'EOF';
<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html xml:lang="en-US" xmlns="http://www.w3.org/1999/xhtml">
<head>
<title>Foo</title>
<meta content="text/html; charset=utf-8" http-equiv="Content-Type"/>
</head>
<body>
<h1>Hello</h1>
<p>File</p>
</body>
</html>
EOF
close($o) or die $!;

my $lint = HTML::Lint->new;

$lint->parse_file($OUTPUT_FN);

is_deeply( [map { $_->as_string() } $lint->errors()], [], 'HTML is valid for output file.' );
