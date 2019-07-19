#!/usr/bin/env perl

use strict;
use warnings;

use HTML::Packer;

use Test::More tests => 7;

my @tests = (
    {
        description => 'blank html',
        config => {
            do_csp => 'sha256',
        },
        csp => {
            'script-src' => [qw(
            )],
            'style-src' => [qw(
            )],
        },
        html => <<'EOS',
EOS
    },
    {
        description => 'blank html, blank hash name',
        config => {
            do_csp => '',
        },
        csp => {
            'script-src' => [qw(
            )],
            'style-src' => [qw(
            )],
        },
        html => <<'EOS',
EOS
    },
    {
        description => '<script> & <style> in <head>, sha256',
        config => {
            do_csp => 'sha256',
            html5 => 1,
        },
        csp => {
            'script-src' => [qw(
                'sha256-791JliCfVfBg+ax8zg5KqhP+kgkqzbJzBcpFDrZQnkc='
            )],
            'style-src' => [qw(
                'sha256-gpov5n8Iw6K+eZE3oYxcBsd5VOOwt1qfH39cYA1/dIg='
            )],
        },
        html => <<'EOS',
<!DOCTYPE html>
<html>
    <head>
        <title>Hello!</title>
        <script>
            alert("hello, world");
        </script>
        <style>
            body {
                background: #000000;
            }
        </style>
    </head>
    <body>
        Hello, World!
    </body>
</html>
EOS
    },
    {
        description => 'multiple <script>s in <head> & <body>, sha384',
        config => {
            do_csp => 'sha384',
        },
        csp => {
            'script-src' => [qw(
                'sha384-GmztkaupfNN5LCa4R3NR92UcwhOPA0C1u4dfOmu7LVDgWTK/nb06W1MXUmCXcC7d='
                'sha384-2MKGGo4REN2gDPFYzCEFbsBLEaaGWN3NtW+5ss3IynhQy0gVzGNjPhIAaQkQsRzl='
                'sha384-bMGstjmVvi+Hidcx4LpW/d3H8fNrKdkuh7zPgP7ygX/nKjqkKGgkJYFCgp7T91wP='
                'sha384-8QFfvbKGXjYGVXD3XCs7As+GxXSe2QOYlCfZK0BwnXoRQnysSDUqmxiQl0gFz3Xv='
            )],
            'style-src' => [qw(
            )],
        },
        html => <<'EOS',
<html>
    <head>
        <script type="javascript">
            alert("hello, world");
        </script>
    </head>
    <body>
        Hello, World!
        <script type="text/javascript">
            alert("bye, world");
        </script>
        <script type="text/javascript">
            alert("this could be a stored XSS!");
        </script>
    </body>
    <script type="javascript">
        alert("carrier-injected code goes here");
    </script>
</html>
EOS
    },
    {
        description => 'multiple <style>s in <head> & <body>, sha512',
        config => {
            do_csp => 'sha512',
            html5 => 1,
        },
        csp => {
            'script-src' => [qw(
            )],
            'style-src' => [qw(
                'sha512-p9OaSbAhJQugXiYS8mIifrN8EMZS/iS6kfXXRS3CJ4Wi2q5Swk43qD4qDHh2ZhNSQHCfMM0Nq5WSVCcJQJgzhA='
                'sha512-Sjc3MfusJO7rZv+3DuUKu3BKqJSS7OH5/hD6hi6wmknbvPQIoKj1XjorMqvIh4cV+5G4wPGw8iyVqr+lM0o00w='
                'sha512-jJo/nufQ7bS7CPfSlVJMOgIwWF+1xWwd+iHHV1XihxC+XK6iXZHB4CCJfyvQxxqWRMy7EjE14pAkLCPXEo1j0Q='
                'sha512-sRmk48iK0P8JDwS5lnbl6J+QxUScQcljqlbZMEJsUkEuuA3023udi0n/v2thOx8Tkl5QVnGKa6PS8Oaopqg5pQ='
            )],
        },
        html => <<'EOS',
<html>
    <head>
        <style type="css">
            body {
                background: #000000;
            }
        </style>
    </head>
    <body>
        Hello, World!
        <style type="text/css">
            p {
                text-align: justify;
            }
        </style>
        <style type="text/css">
            strong {
                color: blue;
            }
        </style>
    </body>
    <style type="css">
        em {
            color: black;
        }
    </style>
</html>
EOS
    },
    {
        description => 'multiple <script>s & <style>s in head & body, sha384',
        config => {
            do_csp => 'sha384',
        },
        csp => {
            'script-src' => [qw(
                'sha384-GmztkaupfNN5LCa4R3NR92UcwhOPA0C1u4dfOmu7LVDgWTK/nb06W1MXUmCXcC7d='
                'sha384-2MKGGo4REN2gDPFYzCEFbsBLEaaGWN3NtW+5ss3IynhQy0gVzGNjPhIAaQkQsRzl='
                'sha384-bMGstjmVvi+Hidcx4LpW/d3H8fNrKdkuh7zPgP7ygX/nKjqkKGgkJYFCgp7T91wP='
                'sha384-8QFfvbKGXjYGVXD3XCs7As+GxXSe2QOYlCfZK0BwnXoRQnysSDUqmxiQl0gFz3Xv='
            )],
            'style-src' => [qw(
                'sha384-iJfw3xZ0S3zdRloWe4NmWzVDoRptkdiBAQ3B8XhDUw6VMlxC443ULkJgG5beMXu8='
                'sha384-9fGbWIuKnbrRTHx7Vm3zJqCSQivir+TNWfFDmkdlCRwjC7VaaX2aYE+GNMt9uVB0='
                'sha384-OB6G18VVZ1zX1cocqlzjU8ia9j9xghiouGtDlyW3fJ+BgWM1Sx+EeX2kkB7RksYB='
                'sha384-ubt1ojP5OBH6ean6YYFy8fqGjFhh2vdAYgIqG15FG7YapFYCPqJfmOhQ+3wtvCVM='
            )],
        },
        html => <<'EOS',
<html>
    <head>
        <script type="javascript">
            alert("hello, world");
        </script>
        <style type="text/css">
            body {
                background: #000000;
            }
        </style>
    </head>
    <body>
        Hello, World!
        <script type="text/javascript">
            alert("bye, world");
        </script>
        <style type="text/css">
            p {
                text-align: justify;
            }
        </style>
        <style type="text/css">
            strong {
                color: blue;
            }
        </style>
        <script type="text/javascript">
            alert("this could be a stored XSS!");
        </script>
    </body>
    <script type="javascript">
        alert("carrier-injected code goes here");
    </script>
    <style type="text/css">
        em {
            color: black;
        }
    </style>
</html>
EOS
    },
    {
        description => 'unknown hash algorithm (no hash calculated)',
        config => {
            do_csp => 'unknown435',
        },
        csp => {
            'script-src' => [qw(
            )],
            'style-src' => [qw(
            )],
        },
        html => <<'EOS',
<html>
    <head>
        <title>Hello!</title>
        <script>
            alert("hello, world");
        </script>
        <style>
            body {
                background: #000000;
            }
        </style>
    </head>
    <body>
        Hello, World!
    </body>
</html>
EOS
    },
);

foreach my $test ( @tests ) {
    my $packer = HTML::Packer->init;

    my $html = $test->{html};
    $packer->minify( \$html, $test->{config} );

    is_deeply( { $packer->csp }, $test->{csp}, $test->{description} );
}
