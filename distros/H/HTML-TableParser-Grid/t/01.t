use strict;
use warnings;
use Carp;
use Test::More 'no_plan';
use Test::Exception;
use Test::NoWarnings;
use HTML::TableParser::Grid;

undef $/;
my $html = <DATA>;

my $parser;
lives_ok { $parser = HTML::TableParser::Grid->new($html) } 'new($html)';
ok $parser, 'new' or die $@;

is $parser->cell(0,0), '00', 'cell(0,0)';
is $parser->cell(0,2), '02-12', 'cell(0,2)';
is $parser->cell(1,1), '10-11', 'cell(1,1)';

my @row = $parser->row(1);
is_deeply \@row, [ qw/10-11 10-11 02-12/ ], 'row(1)';

my @column = $parser->column(1);
is_deeply \@column, [ qw/01 10-11/ ], 'column(1)';

is $parser->num_columns, 3, 'num_columns';
is $parser->num_rows, 2, 'num_rows';

lives_ok { $parser = HTML::TableParser::Grid->new($html, 1) } 'new($html, 1)';
ok $parser, 'new' or die $@;

is $parser->cell(1,1), '00', 'cell(1,1)';
is $parser->cell(1,3), '02-12', 'cell(1,3)';
is $parser->cell(2,2), '10-11', 'cell(2,2)';

__DATA__
<table>
  <tr>
    <td>00</td>
    <td>01</td>
    <td rowspan="2">02-12</td>
  </tr>
  <tr>
    <td colspan="2">10-11</td>
  </tr>
</table>
