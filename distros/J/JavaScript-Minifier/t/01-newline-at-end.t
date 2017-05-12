#!perl -T

use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 2;

#####
##### This test ensures that if the file contains a new line at the end
##### then that newline will be preserved
##### The read-from-file tests for this are in JavaScript-Minifier.t
#####

use JavaScript::Minifier;

my $js_with_new_line = <<'END';
function (s) { alert("Foo"); }
END

chomp( my $js_without_new_line = $js_with_new_line );

like(
    minify(input => $js_with_new_line),
    qr/\n\z/,
    'Last new line was preserved',
);

like(
    minify(input => $js_without_new_line),
    qr/[^\n]\z/,
    'Last new line was not added because it was absent originally',
);