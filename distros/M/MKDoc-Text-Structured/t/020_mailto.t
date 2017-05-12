use warnings;
use strict;
use Test::More 'no_plan';
use lib ('lib', '../lib');
use MKDoc::Text::Structured;

my $text = undef;

$text = MKDoc::Text::Structured::process ('This is a test: mailto:info@mkdoc.com');
is ($text, '<p>This is a test: <a href="mailto:info@mkdoc.com">info@mkdoc.com</a></p>');

__END__
