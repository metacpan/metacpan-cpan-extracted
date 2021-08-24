#!/usr/bin/env perl
use Markdown::Compiler::Test;
use Data::Section::Simple qw( get_data_section );

build_and_test( "One basic table", get_data_section('markdown'), [
    [ "dump_lexer" => 1 ],
    [ "dump_parser" => 1 ],
    [ result_is => get_data_section('html') ],
]);

done_testing;

__DATA__

@@ markdown
| Foo |
|-----|
| Baz |

@@ html
<table>
<tr>
<th>Foo </th>
</tr>
<tr>
<td>Baz </td>
</tr>
</table>

