use warnings;
use strict;
use Test::More 'no_plan';
use lib ('lib', '../lib');
use MKDoc::Text::Structured;

my $text = undef;

$text = MKDoc::Text::Structured::process ('This :-)is a;-) test :-(');
is ($text, '<p>This <span class="smiley-happy">:-)</span>is a;-) test <span class="smiley-sad">:-(</span></p>');

$text = MKDoc::Text::Structured::process ('test &-) test');
is ($text, '<p>test &amp;-) test</p>');

$text = MKDoc::Text::Structured::process ('BBC (Brit Broad Corp :-) test');
is ($text, '<p><abbr title="Brit Broad Corp :-">BBC</abbr> (Brit Broad Corp <span class="smiley-happy">:-)</span> test</p>');

$text = MKDoc::Text::Structured::process ('BBC(Brit Broad Corp :-) test');
is ($text, '<p><abbr title="Brit Broad Corp :-">BBC</abbr> test</p>');

$text = MKDoc::Text::Structured::process ('BBC(Brit Broad Corp :-( ) test');
is ($text, '<p><abbr title="Brit Broad Corp :-(">BBC</abbr> test</p>');

$text = MKDoc::Text::Structured::process ('This is a test: mailto:-)@mkdoc.com');
is ($text, '<p>This is a test: <a href="mailto:-)@mkdoc.com">-)@mkdoc.com</a></p>');

__END__
