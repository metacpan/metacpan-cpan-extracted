use Test::Base;
use HTML::WidgetValidator;

sub validate {
  my $validateor = HTML::WidgetValidator->new(widgets => [ 'Imageloop' ]);
  my $result  = $validateor->validate(shift);
  return $result ? $result->name : ' ';
}

filters {
    input    => [qw/chomp validate/],
    expected => [qw/chomp/],
};

__END__

=== Imageloop 1
--- input
<embed src="http://www.imageloop.com/looopSlider.swf?id=4f27e23b-5a23-1c81-8b6b-0015c5fcf7da&c=01,01,02,01" type="application/x-shockwave-flash" quality="high" scale="noscale" salign="l" wmode="transparent" width="425" height="325" style="width:425px;height:325px;" align="middle"></embed>
--- expected
imageloop

=== Imageloop 2
--- input
<embed src="http://www.imageloop.com/looopSlider.swf?id=263df482-5df8-166a-a4cf-0015c5fcf7da&c=01,01,02,01" type="application/x-shockwave-flash" quality="high" scale="noscale" salign="l" wmode="transparent" name="imageloop" width="425" height="325" style="width:425px;height:325px;" align="middle"></embed>
--- expected
imageloop
