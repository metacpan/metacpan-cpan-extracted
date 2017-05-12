#!perl

use strict;
use warnings;

use Test::More;
use Test::Differences;
use Cwd qw(getcwd chdir);
use English qw(-no_match_vars $CHILD_ERROR);

$ENV{AUTHOR_TESTING} or plan
    skip_all => 'Set $ENV{AUTHOR_TESTING} to run this test.';

my @data = (
    {
        test   => '01_clean_string',
        path   => 'example',
        script => '01_clean_string.pl',
        params => '-I../lib',
        result => <<'EOT',
Filter swichted temporary off.
------------------------------
<html>
    <title>Title</title>
    <body>
        top body text
        <span>
            in

            span
        </span>
        <pre>
P
  R
    E
        </pre>
        <textarea>
text
     area
         </textarea>
     </body>
</html>

filtered
--------
<html>
<title>Title</title>
<body>
top body text
<span>
in
span
</span>
<pre>
P
  R
    E
        </pre>
<textarea>
text
     area
         </textarea>
</body>
</html>

EOT
    },
    {
        test   => '02_clean_template',
        path   => 'example',
        script => '02_clean_template.pl',
        params => '-I../lib',
        result => do { my $text = <<'EOT'; $text =~ s{\\s}{ }xmsg; $text },
Filter swichted temporary off.
------------------------------
<html>
<title>title</title>
<body>
    Something
             written
                    inside
                          of
                            the
                               template.
    parameter\s
\s
         param
</body>
</html>

filtered
--------
<html>
<title>title</title>
<body>
Something
written
inside
of
the
template.
parameter\s
\s
         param
</body>
</html>

EOT
    },
    {
        test   => '03_clean_all',
        path   => 'example',
        script => '03_clean_all.pl',
        params => '-I../lib',
        result => <<'EOT',
<html>
<title>title</title>
<body>
Something
written
inside
of
the
template.
parameter
param
</body>
</html>
EOT
    },
);

plan tests => 0 + @data;

for my $data (@data) {
    my $dir = getcwd();
    chdir "$dir/$data->{path}";
    my $result = qx{perl $data->{params} $data->{script} 2>&1};
    $CHILD_ERROR
        and die "Couldn't run $data->{script} (status $CHILD_ERROR)";
    chdir $dir;
    eq_or_diff
        $result,
        $data->{result},
        $data->{test};
}
