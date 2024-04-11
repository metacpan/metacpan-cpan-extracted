use strict;
use warnings;
use utf8;

use Markdown::Perl;
use Test2::V0;

my $yaml = Markdown::Perl->new(parse_file_metadata => 'yaml');

is($yaml->convert("---\nfoo: bar\nbaz: bin\n---\ndum\n"), "<p>dum</p>\n", 'yaml_table');
is($yaml->convert("---\nfoo: bar\nbaz: bin\n...\ndum\n"), "<p>dum</p>\n", 'yaml_table_with_dot');
is($yaml->convert("---\nfoo: bar\n\n...\ndum\n"), "<hr />\n<p>foo: bar</p>\n<p>...\ndum</p>\n", 'yaml_with_empty_line');
is($yaml->convert("---\n+ foo\n...\ndum\n"), "<hr />\n<ul>\n<li>foo\n...\ndum</li>\n</ul>\n", 'not_yaml');

done_testing;
