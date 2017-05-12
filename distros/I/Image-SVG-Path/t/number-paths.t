use warnings;
use strict;
use utf8;
use Test::More;
my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";
binmode STDOUT, ":encoding(utf8)";
binmode STDERR, ":encoding(utf8)";
use warnings;
use strict;
use Test::More;
use Image::SVG::Path qw/extract_path_info/;

# Test these different syntaxes to check for path parsing

my @strings = (
    'M150 0 L75 200 L225 200 Z',       'Condensed',
    'M 150 0 L 75 200 L 225 200 Z',    'Whitespace only',
    'M 150 0,L 75 200,L 225 200,Z',    'Commas between commands',
    'M 150 0, L 75 200, L 225 200, Z', 'Commas & whitespace between commands',
    'M 150 0 L 75 200 225 200 Z',      'Repeated command, implicit',
    'M 150 0 L 75,200 225,200 Z',      'Commas inside pairs',
    'M 150 0 L 75,200,225,200 Z',      'Commas inside and between pairs',
    'M 150 0 L 75 200,225 200 Z',      'Commas between pairs only',
    'M 150 0 L 75, 200, 225, 200 Z',   'Commas and whitespace inside and between pairs',
    'M 150 0 L 75 200, 225 200 Z',     'Commas and whitespace between pairs only',
    'M 150 0, L 75 200, 225 200, Z',   'Commas and whitespace between pairs and commands',
);

while (my ($string, $comment) = splice @strings, 0, 2) {
    eval {
	my @foo = extract_path_info ($string);
    };
    if ($@) {
	note ($@);
    }
    ok (! $@);
}

done_testing ();
