use strict;
use warnings;
use utf8;
use Test::More tests => 1 + 1 + 2;
use Test::NoWarnings;
use Test::Warn;

warnings_like {
	require HTML::Hyphenate;
} [
], 'Warned about unescaped left brace in TeX::Hyphen';


my $hyphenator = HTML::Hyphenate->new();

$hyphenator->default_lang(q{en-us});

is( $hyphenator->hyphenated(q{
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Roland van Ipenburg, technical experience design consultant</title>
</head>
<body>
</body>
</html>
}),
    q{
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Roland van Ipenburg, technical ex­pe­ri­ence design con­sul­tant</title>
</head>
<body>
</body>
</html>
}, q{HTML5 including DOCTYPE} );

my $msg = 'Author test. Set $ENV{AUTHOR_TESTING} to a true value to run.';
SKIP: {
    skip $msg, 1 unless $ENV{AUTHOR_TESTING};
}
$ENV{AUTHOR_TESTING} && Test::NoWarnings::had_no_warnings();
