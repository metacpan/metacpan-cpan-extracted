use strict;
use warnings;

use HTML::TokeParser ();
use Test::More tests => 17;


# First we create an HTML document to test

my $file = "ttest$$.htm";
die "$file already exists" if -e $file;

{
    open(my $fh, '>', $file) or die "Can't create $file: $!";
    print {$fh} <<'EOT';

<!--This is a test-->
<html><head><title>
  This is the &lt;title&gt;
</title>

  <base href="http://www.perl.com">
</head>

<body background="bg.gif">

    <h1>This is the <b>title</b> again
    </h1>

    And this is a link to the <a href="http://www.perl.com"><img src="camel.gif" alt="Perl">&nbsp;<!--nice isn't it-->Institute</a>

   <br/><? process instruction >

</body>
</html>

EOT
    close($fh);
}

END { unlink($file) || warn "Can't unlink $file: $!"; }

my $p;

$p = HTML::TokeParser->new($file) || die "Can't open $file: $!";
ok($p->unbroken_text);
if ($p->get_tag("foo", "title")) {
    my $title = $p->get_trimmed_text;

    #diag "Title: $title";
    is($title, "This is the <title>");
}
undef($p);

my $scount = 0;
my $ecount = 0;
my $tcount = 0;
my $pcount = 0;

# Test with reference to glob
{
    open(my $fh, '<', $file) || die "Can't open $file: $!";
    $p = HTML::TokeParser->new($fh);
    while (my $token = $p->get_token) {
        $scount++ if $token->[0] eq "S";
        $ecount++ if $token->[0] eq "E";
        $pcount++ if $token->[0] eq "PI";
    }
    undef($p);
    close $fh;
}

# Test with glob
{
    open(my $fh, $file) || die "Can't open $file: $!";
    $p = HTML::TokeParser->new($fh);
    $tcount++ while $p->get_tag;
    undef($p);
    close $fh;
}

# Test with plain file name
$p = HTML::TokeParser->new($file) || die;
$tcount++ while $p->get_tag;
undef($p);

#diag "Number of tokens found: $tcount/2 = $scount + $ecount";
is($tcount,     34);
is($scount,     10);
is($ecount,     7);
is($pcount,     1);
is($tcount / 2, $scount + $ecount);

ok(!HTML::TokeParser->new("/noT/thEre/$$"));

$p = HTML::TokeParser->new($file) || die;
$p->get_tag("a");
my $atext = $p->get_text;
undef($p);

is($atext, "Perl\240Institute");

# test parsing of embeded document
$p = HTML::TokeParser->new(\<<HTML);
<title>Title</title>
<H1>
Heading
</h1>
HTML

ok($p->get_tag("h1"));
is($p->get_trimmed_text, "Heading");
undef($p);

# test parsing of large embedded documents
my $doc = "<a href='foo'>foo is bar</a>\n\n\n" x 2022;

#use Time::HiRes qw(time);
my $start = time;
$p = HTML::TokeParser->new(\$doc);

#diag "Construction time: ", time - $start;

my $count;
while (my $t = $p->get_token) {
    $count++ if $t->[0] eq "S";
}

#diag "Parse time: ", time - $start;

is($count, 2022);

$p = HTML::TokeParser->new(\<<'EOT');
<H1>This is a heading</H1>
This is s<b>o</b>me<hr>text.
<br />
This is some more text.
<p>
This is even some more.
EOT

$p->get_tag("/h1");

my $t = $p->get_trimmed_text("br", "p");
is($t, "This is some text.");

$p->get_tag;

$t = $p->get_trimmed_text("br", "p");
is($t, "This is some more text.");

undef($p);

$p = HTML::TokeParser->new(\<<'EOT');
<H1>This is a <b>bold</b> heading</H1>
This is some <i>italic</i> text.<br />This is some <span id=x>more text</span>.
<p>
This is even some more.
EOT

$p->get_tag("h1");

$t = $p->get_phrase;
is($t, "This is a bold heading");

$t = $p->get_phrase;
is($t, "");

$p->get_tag;

$t = $p->get_phrase;
is($t, "This is some italic text. This is some more text.");

undef($p);
