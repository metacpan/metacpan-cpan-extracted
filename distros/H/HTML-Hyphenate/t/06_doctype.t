use strict;
use warnings;
use utf8;
use Test::More tests => 5 + 1;
$ENV{AUTHOR_TESTING} && eval { require Test::NoWarnings };

use HTML::Hyphenate;
my $hyphenator = HTML::Hyphenate->new();

$hyphenator->default_lang(q{en-us});

is( $hyphenator->hyphenated(q{
<!DOCTYPE html>
<html lang="en_us">
<head>
<meta charset="utf-8">
<title>Roland van Ipenburg, technical experience design consultant</title>
</head>
<body>
<h1><span lang="nl">Roland van Ipenburg</span>, technical experience design consultant</h1>
</body>
</html>
}),
    q{
<!DOCTYPE html>
<html lang="en_us">
<head>
<meta charset="utf-8">
<title>Roland van Ipenburg, technical ex­pe­ri­ence design con­sul­tant</title>
</head>
<body>
<h1><span lang="nl">Roland van Ipenburg</span>, technical ex­pe­ri­ence design con­sul­tant</h1>
</body>
</html>
}, q{HTML5 without including DOCTYPE en_us} );

is( $hyphenator->hyphenated(q{
<html lang="en_us">
<head>
<meta charset="utf-8">
<title>Roland van Ipenburg, technical experience design consultant</title>
</head>
<body>
</body>
</html>
}),
    q{
<html lang="en_us">
<head>
<meta charset="utf-8">
<title>Roland van Ipenburg, technical ex­pe­ri­ence design con­sul­tant</title>
</head>
<body>
</body>
</html>
}, q{HTML5 without including DOCTYPE en_us} );

is( $hyphenator->hyphenated(q{
<!DOCTYPE html>
<html lang="en_us">
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
<html lang="en_us">
<head>
<meta charset="utf-8">
<title>Roland van Ipenburg, technical ex­pe­ri­ence design con­sul­tant</title>
</head>
<body>
</body>
</html>
}, q{HTML5 including DOCTYPE en_us} );

is( $hyphenator->hyphenated(q{
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
<html lang="en">
<head>
<meta charset="utf-8">
<title>Roland van Ipenburg, technical ex­per­i­ence design con­sult­ant</title>
</head>
<body>
</body>
</html>
}, q{HTML5 without including DOCTYPE en} );

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
<title>Roland van Ipenburg, technical ex­per­i­ence design con­sult­ant</title>
</head>
<body>
</body>
</html>
}, q{HTML5 including DOCTYPE en} );

my $msg = 'Author test. Set $ENV{AUTHOR_TESTING} to a true value to run.';
SKIP: {
    skip $msg, 1 unless $ENV{AUTHOR_TESTING};
}
$ENV{AUTHOR_TESTING} && Test::NoWarnings::had_no_warnings();
