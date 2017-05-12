use Test::Base;
use HTML::WidgetValidator;

sub validate {
  my $validateor = HTML::WidgetValidator->new(widgets => [ 'Alpslab' ]);
  my $result  = $validateor->validate(shift);
  return $result ? $result->name : ' ';
}

filters {
    input    => [qw/chomp validate/],
    expected => [qw/chomp/],
};

__END__

=== Alpslab Video 1
--- input
<object codebase="http://fpdownload.macromedia.com/pub/shockwave/cabs/flash/swflash.cab#version=8,0,22,0" width="400" height="330"><param name="movie" value="http://video.alpslab.jp/svideoslide.swf" /><param name="flashvars" value="lapid=d91fffb84be11cf159e9295b925d4e80" /><embed src="http://video.alpslab.jp/svideoslide.swf" width="400" height="330" type="application/x-shockwave-flash" flashvars="lapid=d91fffb84be11cf159e9295b925d4e80" /></object>
--- expected
ALPSLAB

=== Alpslab Video 2
--- input
<object codebase="http://fpdownload.macromedia.com/pub/shockwave/cabs/flash/swflash.cab#version=8,0,22,0" width="400" height="330"><param name="movie" value="http://video.alpslab.jp/svideoslide.swf" /><param name="flashvars" value="lapid=2df3d0ac7799e3b8868375362779a01c" /><embed src="http://video.alpslab.jp/svideoslide.swf" width="400" height="330" type="application/x-shockwave-flash" flashvars="lapid=2df3d0ac7799e3b8868375362779a01c" /></object>
--- expected
ALPSLAB

=== Alpslab Route
--- input
<object codebase="http://fpdownload.macromedia.com/pub/shockwave/cabs/flash/swflash.cab#version=8,0,22,0" width="320" height="240"><param name="movie" value="http://route.alpslab.jp/fslide.swf" /><param name="flashvars" value="routeid=21710ffee1b885e5e91879c2d4312839" /><embed src="http://route.alpslab.jp/fslide.swf" width="320" height="240" type="application/x-shockwave-flash" flashvars="routeid=21710ffee1b885e5e91879c2d4312839" /></object>
--- expected
ALPSLAB

=== Alpslab Base
--- input
<script type="text/javascript" src="http://mybase.alpslab.jp/mybase.js"></script>
--- expected
ALPSLAB

=== Alpslab Slide
--- input
<script type="text/javascript" src="http://slide.alpslab.jp/scrollmap.js"></script>
--- expected
ALPSLAB

