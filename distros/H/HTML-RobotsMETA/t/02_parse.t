use strict;
use Test::More (tests => 17);

BEGIN
{
    use_ok("HTML::RobotsMETA");
}


my $p = HTML::RobotsMETA->new();

{
    my $r = $p->parse_rules(<<EOM);
<html>
<head>
    <meta name="http-equiv" content="text/html; charset=utf-8">
    <meta name="robots"     content="nofollow, noindex">
</head>
<body>
    <div>hello, world</div>
</body>
</html>
EOM

    ok($r);
    ok(! $r->can_follow,  "Can't follow as expected");
    ok(! $r->can_index,   "Can't index as expected");
    ok(  $r->can_archive, "Can archive as expected");
}

{
    my $r = $p->parse_rules(<<EOM);
<html>
<head>
    <meta name="http-equiv" content="text/html; charset=utf-8">
    <meta name="robots"     content="follow, noindex">
</head>
<body>
    <div>hello, world</div>
</body>
</html>
EOM

    ok($r);
    ok(  $r->can_follow,  "Can follow as expected");
    ok(! $r->can_index,   "Can't index as expected");
    ok(  $r->can_archive, "Can archive as expected");
}

{
    my $r = $p->parse_rules(<<EOM);
<html>
<head>
    <meta name="http-equiv" content="text/html; charset=utf-8">
    <meta name="robots"     content="NONE">
</head>
<body>
    <div>hello, world</div>
</body>
</html>
EOM

    ok($r);
    ok(! $r->can_follow,  "Can't follow as expected");
    ok(! $r->can_index,   "Can't index as expected");
    ok(! $r->can_archive, "Can't archive as expected");
}

{
    my $r = $p->parse_rules(<<EOM);
<html>
<head>
    <meta name="http-equiv" content="text/html; charset=utf-8">
    <meta name="robots"     content="ALL">
</head>
<body>
    <div>hello, world</div>
</body>
</html>
EOM

    ok($r);
    ok(  $r->can_follow,  "Can follow as expected");
    ok(  $r->can_index,   "Can index as expected");
    ok(  $r->can_archive, "Can archive as expected");
}

