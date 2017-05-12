use warnings;
use strict;
use Test::More 'no_plan';
use lib ('lib', '../lib');
use MKDoc::Text::Structured;

my $text = undef;

$MKDoc::Text::Structured::Inline::NoFollow = 1;

$text = MKDoc::Text::Structured::process ("This is a test: http://www.google.com/");
is ($text, '<p>This is a test: <a href="http://www.google.com/" rel="nofollow">http://www.google.com/</a></p>');

$text = MKDoc::Text::Structured::process ("This is a test: <http://www.google.com/>");
is ($text, '<p>This is a test: &lt;<a href="http://www.google.com/" rel="nofollow">http://www.google.com/</a>&gt;</p>');

$text = MKDoc::Text::Structured::process ("This is a test: http://www.google.com/?a=b&c=d");
is ($text, '<p>This is a test: <a href="http://www.google.com/?a=b&amp;c=d" rel="nofollow">http://www.google.com/?a=b&amp;c=d</a></p>');

undef $MKDoc::Text::Structured::Inline::NoFollow;

$text = MKDoc::Text::Structured::process ("This is a test: http://www.google.com/");
is ($text, '<p>This is a test: <a href="http://www.google.com/">http://www.google.com/</a></p>');

__END__
