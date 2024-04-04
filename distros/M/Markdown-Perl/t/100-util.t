use strict;
use warnings;
use utf8;

use Markdown::Perl::Util ':all';
use Test2::V0;

{
  my @a = (2, 4, 6, 7, 8, 9, 10);
  is([split_while { $_ % 2 == 0 } @a], [[2, 4, 6], [7, 8, 9, 10]], 'split_while1');
  is (\@a, [2, 4, 6, 7, 8, 9, 10], 'split_while2');
}

{
  my @a = (2, 4, 6);
  is([split_while { $_ % 2 == 0 } @a], [[2, 4, 6], []], 'split_while3');
}

is(remove_prefix_spaces(0, 'test'), 'test', 'remove_prefix_spaces1');
is(remove_prefix_spaces(0, '  test'), '  test', 'remove_prefix_spaces2');
is(remove_prefix_spaces(0, '    test'), '    test', 'remove_prefix_spaces3');
is(remove_prefix_spaces(2, '    test'), '  test', 'remove_prefix_spaces4');
is(remove_prefix_spaces(2, ' test'), 'test', 'remove_prefix_spaces5');
is(remove_prefix_spaces(2, 'test'), 'test', 'remove_prefix_spaces6');
is(remove_prefix_spaces(2, '    test'), '  test', 'remove_prefix_spaces7');
is(remove_prefix_spaces(2, "\ttest"), '  test', 'remove_prefix_spaces8');
is(remove_prefix_spaces(2, " \ttest"), "  test", 'remove_prefix_spaces9');
is(remove_prefix_spaces(2, "  \ttest"), "  test", 'remove_prefix_spaces10');
is(remove_prefix_spaces(2, "    \ttest"), "      test", 'remove_prefix_spaces11');
is(remove_prefix_spaces(4, '    test'), 'test', 'remove_prefix_spaces12');
is(remove_prefix_spaces(4, '      test'), '  test', 'remove_prefix_spaces13');
is(remove_prefix_spaces(8, '        test'), 'test', 'remove_prefix_spaces14');
is(remove_prefix_spaces(8, '          test'), '  test', 'remove_prefix_spaces15');
is(remove_prefix_spaces(2, "  \n"), "\n", 'remove_prefix_spaces16');
is(remove_prefix_spaces(2, "\t\ttest"), "\t  test", 'remove_prefix_spaces17');
is(remove_prefix_spaces(4, "\t\ttest"), "\ttest", 'remove_prefix_spaces18');
is(remove_prefix_spaces(4, "\t\ttest", 0), "    test", 'remove_prefix_spaces19');

is(indent_size("abc"), 0, 'indent_size1');
is(indent_size(" abc"), 1, 'indent_size2');
is(indent_size("    abc"), 4, 'indent_size3');
is(indent_size("\tabc"), 4, 'indent_size4');
is(indent_size("  \tabc"), 4, 'indent_size5');
is(indent_size("  \t  abc"), 6, 'indent_size6');
is(indent_size("  \t     abc"), 9, 'indent_size7');
is(indent_size("\t\tabc"), 8, 'indent_size8');

is(horizontal_size("ab\tcd"), 6, 'horizontal_size1');
is(horizontal_size("ab\t\tcd"), 10, 'horizontal_size2');
is(horizontal_size("\t\tcd"), 10, 'horizontal_size3');
is(horizontal_size("abcd\t"), 8, 'horizontal_size4');
is(horizontal_size("ab"), 2, 'horizontal_size5');

is(indented_one_tab("abc"), F(), 'indented_one_tab0');
is(indented_one_tab("   abc"), F(), 'indented_one_tab1');
is(indented_one_tab("    abc"), T(), 'indented_one_tab2');
is(indented_one_tab("xxx    abc"), F(), 'indented_one_tab3');
is(indented_one_tab("\tabc"), T(), 'indented_one_tab4');
is(indented_one_tab("  \tabc"), T(), 'indented_one_tab5');

is(indented(2, 'foo'), F(), 'indented1');
is(indented(2, ' foo'), F(), 'indented2');
is(indented(2, '  foo'), T(), 'indented3');
is(indented(2, '    foo'), T(), 'indented4');
is(indented(2, "\tfoo"), T(), 'indented5');
is(indented(0, "\tfoo"), T(), 'indented6');
is(indented(0, "foo"), T(), 'indented7');
is(indented(5, "\t\tfoo"), T(), 'indented8');
is(indented(5, "     foo"), T(), 'indented9');
is(indented(5, "    foo"), F(), 'indented10');

done_testing;
