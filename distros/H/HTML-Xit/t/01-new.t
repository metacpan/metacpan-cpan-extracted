use strict;
use warnings FATAL => 'all';

use Data::Dumper;
use Test::More;

BEGIN {
    use_ok('HTML::Xit');
}

my($html, $in, $X);

# get new instance from test file
$X = HTML::Xit->new("t/data/test.html");
ok($X, "new from file string");
ok($X->("#para1")->text =~ m{Lorem ipsum}, "content correct");

# get a new instance from a file handle
open($in, "<", "t/data/test.html");
ok($in, "file handle opened");

$X = HTML::Xit->new($in);
ok($X, "new from file handle");
ok($X->("#para1")->text =~ m{Lorem ipsum}, "content correct");

close $in;

# get a new instance from text
{
    open($in, "<", "t/data/test.html");
    local $/ = undef;
    $html = <$in>;
    close $in;
}

$X = HTML::Xit->new($html);
ok($X, "new from scalar");
ok($X->("#para1")->text =~ m{Lorem ipsum}, "content correct");

$X = HTML::Xit->new(\$html);
ok($X, "new from scalar ref");
ok($X->("#para1")->text =~ m{Lorem ipsum}, "content correct");

# get new instance from web page
$X = HTML::Xit->new("http://search.cpan.org");
ok($X, "new from web page");
ok($X->("title")->text =~ m{cpan}i, "content correct");

# new instance with invalid args should undef
$X = HTML::Xit->new([1]);
ok(!$X, "undef on invalid args");

done_testing();
