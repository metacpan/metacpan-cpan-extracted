use Test::Base;
use HTML::WidgetValidator;

sub validate {
  my $validateor = HTML::WidgetValidator->new(widgets => [ 'Twitter' ]);
  my $result  = $validateor->validate(shift);
  return $result ? $result->name : ' ';
}

filters {
    input    => [qw/chomp validate/],
    expected => [qw/chomp/],
};

__END__

=== Twitter1
--- input
<embed src="http://twitter.com/flash/twitter_badge.swf"  flashvars="color1=6736896&type=user&id=2922721"  quality="high" width="176" height="176" name="twitter_badge" align="middle" allowScriptAccess="always" wmode="transparent" type="application/x-shockwave-flash" pluginspage="http://www.macromedia.com/go/getflashplayer" />
--- expected
Twitter

=== Twitter2
--- input
<embed src="http://static.twitter.com/flash/twitter_timeline_badge.swf" flashvars="user_id=2922721&color1=0xFFFFCE&color2=0xFCE7CC&textColor1=0x4A396D&textColor2=0xBA0909&backgroundColor=0x92E2E5&textSize=10" width="200" height="400" quality="high" name="twitter_timeline_badge" align="middle" type="application/x-shockwave-flash" allowScriptAccess="always" type="application/x-shockwave-flash" pluginspage="http://www.adobe.com/go/getflashplayer"></embed>
--- expected
Twitter

=== Twitter3
--- input
<script type="text/javascript" src="http://twitter.com/javascripts/blogger.js"></script>
--- expected
Twitter

=== Twitter4
--- input
<script text="text/javascript" src="http://twitter.com/statuses/user_timeline/nagayama.json?callback=twitterCallback2&count=5"></script>
--- expected
Twitter

=== Twitter5
--- input
<script text="text/javascript" src="http://twitter.com/statuses/user_timeline/hogehoge.json?callback=twitterCallback2&count=5"></script>
--- expected
Twitter
