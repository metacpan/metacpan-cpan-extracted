use Test::Base;
use HTML::WidgetValidator;

sub validate {
  my $validateor = HTML::WidgetValidator->new(widgets => [ 'Rimo' ]);
  my $result  = $validateor->validate(shift);
  return $result ? $result->name : ' ';
}

filters {
    input    => [qw/chomp validate/],
    expected => [qw/chomp/],
};

__END__

=== Rimo
--- input
<object width="320" height="240" classid="clsid:D27CDB6E-AE6D-11cf-96B8-444553540000">
<param name="movie" value="http://rimo.tv/tools/mini.swf?v1.1"></param>
<param name="FlashVars" value="channelId=2579&serverRoot=http%3A%2F%2Frimo.tv%2F&lang=ja&autoPlay=0"></param>
<embed src="http://rimo.tv/tools/mini.swf?v1.1" type="application/x-shockwave-flash" width="320" height="240" FlashVars="channelId=2579&serverRoot=http%3A%2F%2Frimo.tv%2F&lang=ja&autoPlay=0"></embed>
<noembed><a href="http://rimo.tv/ja/ch/2579">Rimo</a>
</noembed>
</object>
--- expected
Rimo
