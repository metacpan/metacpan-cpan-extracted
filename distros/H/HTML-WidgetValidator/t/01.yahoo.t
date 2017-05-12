use Test::Base;
use HTML::WidgetValidator;

sub validate {
  my $validateor = HTML::WidgetValidator->new(widgets => [ 'YahooWeatherJP','YahooTopicsJP' ]);
  my $result  = $validateor->validate(shift);
  return $result ? $result->name : ' ';
}

filters {
    input    => [qw/chomp validate/],
    expected => [qw/chomp/],
};

__END__

=== Yahoo Weather 1
--- input
<script>var CFLwidth = "150";var CFLheight = "322";var CFLswfuri = "http://i.yimg.jp/images/weather/blogparts/yj_weather.swf?mapc=4";</script>
--- expected
Yahoo! Weather

=== Yahoo Weather 2
--- input
<script type="text/javascript" charset="euc-jp" src="http://weather.yahoo.co.jp/weather/promo/js/weather.js"></script>
--- expected
Yahoo! Weather

===  Yahoo Topics 1
--- input
<script>var CFLwidth = "150";var CFLheight = "208";var CFLswfuri = "http://i.yimg.jp/i/topics/blogparts/topics_s.swf?genre=entertainment&amp;wakuFontColor=00CCCC&amp;wakuBGColor=3300CC&amp;bodyFontColor=3333FF&amp;bodyBGColor=99FFFF";</script>
--- expected
Yahoo! Topics

=== Yahoo Topics 2
--- input
<script type="text/javascript" charset="euc-jp" src="http://public.news.yahoo.co.jp/blogparts/js/topics.js"></script>
--- expected
Yahoo! Topics


=== Yahoo Topics 3
--- input
<script>var CFLwidth = "222";var CFLheight = "240";var CFLswfuri = "http://i.yimg.jp/i/topics/blogparts/topics.swf?genre=entertainment&amp;wakuFontColor=336699&amp;wakuBGColor=33FFFF&amp;bodyFontColor=FFCC33&amp;bodyBGColor=3333CC";</script>
--- expected
Yahoo! Topics
