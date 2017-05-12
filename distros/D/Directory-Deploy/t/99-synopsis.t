#!/usr/bin/perl -w

use strict;
use warnings;

use Test::Most;

plan qw/no_plan/;

use Directory::Scratch;
use Directory::Deploy;

package My::Assets;

use Directory::Deploy::Declare;

include <<'_END_';
# A line beginning with '#' is ignored
run/
# A path with a trailing slash is a directory (otherwise a file)
run/root/
run/tmp/:700
# A :\d+ after a path is the mode (permissions) for the file/dir
assets/
assets/root/
assets/root/static/
assets/root/static/css/
assets/root/static/js/
assets/tt/
_END_

include
    'assets/tt/frame.tt.html' => \<<'_END_',
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title>[% title %]</title>
<meta http-equiv="Content-Type" content="text/html;charset=utf-8" />
</head>
<body>
<div id="doc2">

    [% content %]

    <div class="footer"> ... </div>

</div>
</body>
</html>
_END_

    'assets/root/static/css/base.css' => \<<'_END_',
body, table {
    font-family: Verdana, Arial, sans-serif;
    background-color: #fff;
}

a, a:hover, a:active, a:visited {
    text-decoration: none;
    font-weight: bold;
    color: #436b95;
}
_END_
; # End of the include

no Directory::Deploy::Declare;

package main;

my ($scratch, $deploy, $manifest);

sub test {

    for(qw{
run/
run/root/
run/tmp/
assets/
assets/root/
assets/root/static/
assets/root/static/css/
assets/root/static/js/
assets/tt/
    }) {
        ok( -d $scratch->dir( $_ ) );
    }
    is( $scratch->dir( '/run/tmp/' )->stat->mode & 07777, 0700 );
#    ok( -f $scratch->file( 'a/b' ) );
#    ok( -d $scratch->dir( 'c/d/e' ) );
#    ok( -f $scratch->file( 'f' ) );
#    is( (stat _)[2] & 07777, 0666 );
#    ok( -f $scratch->file( 'g' ) );
#    is( (stat _)[2] & 07777, 0666 );
#    ok( -f $scratch->file( 'h/i' ) );
#    is( (stat _)[2] & 07777, 0600 );
#    is( $scratch->read( 'h/i' )."\n", <<_END_ );
#This is h/i
#_END_
}

{
    $scratch = Directory::Scratch->new;
    My::Assets->deploy( { base => $scratch->base } );

    test;
}

1;
