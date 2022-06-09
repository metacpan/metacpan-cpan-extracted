use strict;
use warnings;

use Test::More tests => 39;
BEGIN { use_ok('Excel::Writer::XLSX::CDF') };

{
  my $e = Excel::Writer::XLSX::CDF->new;
  isa_ok($e, 'Excel::Writer::XLSX::CDF');
  can_ok($e, 'new');
  can_ok($e, 'chart_title');
  can_ok($e, 'chart_colors');
  can_ok($e, 'chart_x_label');
  can_ok($e, 'chart_y_label');
  can_ok($e, 'group_names_sort');
  can_ok($e, 'generate');
  can_ok($e, 'generate_file');

  is($e->chart_title, 'Continuous Distribution Function (CDF)', 'chart_title');
  isa_ok($e->chart_colors, 'ARRAY', 'chart_colors');
  is($e->chart_x_label, '', 'chart_x_label');
  is($e->chart_y_label, 'Probability', 'chart_y_label');
  ok(!$e->group_names_sort, 'group_names_sort');

  is($e->chart_title('My Title'), 'My Title', 'chart_title');
  isa_ok($e->chart_colors([]), 'ARRAY', 'chart_colors');
  is($e->chart_x_label("X Label"), 'X Label', 'chart_x_label');
  is($e->chart_y_label("Y Label"), 'Y Label', 'chart_y_label');
  ok($e->group_names_sort(1), 'group_names_sort');
}
{
  my $e = Excel::Writer::XLSX::CDF->new(chart_title=>"chart_title", chart_colors=>[], chart_x_label=>"chart_x_label", chart_y_label=>"chart_y_label", group_names_sort=>1);
  isa_ok($e, 'Excel::Writer::XLSX::CDF');
  can_ok($e, 'new');
  can_ok($e, 'chart_title');
  can_ok($e, 'chart_colors');
  can_ok($e, 'chart_x_label');
  can_ok($e, 'chart_y_label');
  can_ok($e, 'group_names_sort');
  can_ok($e, 'generate');
  can_ok($e, 'generate_file');

  is($e->chart_title, 'chart_title', 'chart_title');
  isa_ok($e->chart_colors, 'ARRAY', 'chart_colors');
  is($e->chart_x_label, 'chart_x_label', 'chart_x_label');
  is($e->chart_y_label, 'chart_y_label', 'chart_y_label');
  ok($e->group_names_sort, 'group_names_sort');

  is($e->chart_title('My Title'), 'My Title', 'chart_title');
  isa_ok($e->chart_colors([]), 'ARRAY', 'chart_colors');
  is($e->chart_x_label("X Label"), 'X Label', 'chart_x_label');
  is($e->chart_y_label("Y Label"), 'Y Label', 'chart_y_label');
  ok($e->group_names_sort(1), 'group_names_sort');
}
