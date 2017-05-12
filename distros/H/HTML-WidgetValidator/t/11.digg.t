use Test::Base;
use HTML::WidgetValidator;

sub validate {
  my $validateor = HTML::WidgetValidator->new(widgets => [ 'Digg' ]);
  my $result  = $validateor->validate(shift);
  return $result ? $result->name : ' ';
}

filters {
    input    => [qw/chomp validate/],
    expected => [qw/chomp/],
};

__END__

=== Digg 1
--- input
<script type="text/javascript">
digg_width = '200px';
digg_height = '200px';
digg_border = 0;
digg_count = 0;
digg_description = 1;
digg_target = 1;
digg_theme = 'digg-widget-theme6';
digg_custom_header = '#666666';
digg_custom_border = '#666666';
digg_custom_link = '#cce';
digg_custom_hoverlink = '#6c0';
digg_custom_footer = '#090';
digg_title = 'Popular stories from the source site d.hatena.ne.jp sorted by date';
</script>
--- expected
Digg

=== Digg 2
--- input
<script type="text/javascript" src="http://digg.com/tools/widgetjs"></script>
--- expected
Digg

=== Digg 3
--- input
<script type="text/javascript" src="http://digg.com/tools/services?type=javascript&callback=diggwb&endPoint=/stories/popular&domain=d.hatena.ne.jp&sort=promote_date-desc&count=15"></script>
--- expected
Digg

=== Digg 4
--- input
<script type="text/javascript" src="http://digg.com/tools/services?type=javascript&callback=diggwb&endPoint=/stories/container/entertainment/top&count=10"></script>
--- expected
Digg

=== Digg 5
--- input
<script type="text/javascript">
digg_width = '200px';
digg_height = '200px';
digg_target = 1;
digg_theme = 'digg-widget-theme2';
digg_title = 'Top 10 list from Entertainment';
</script>
--- expected
Digg

=== Digg 6
--- input
<script type="text/javascript">
digg_width = '200px';
digg_height = '200px';
digg_target = 1;
digg_title = 'Top 10 list from Entertainment';
</script>
--- expected
Digg
