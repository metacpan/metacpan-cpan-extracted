use Test::Base;
use HTML::WidgetValidator;

sub validate {
  my $validateor = HTML::WidgetValidator->new(widgets => [ 'GoogleMaps' ]);
  my $result  = $validateor->validate(shift);
  return $result ? $result->name : ' ';
}

filters {
    input    => [qw/chomp validate/],
    expected => [qw/chomp/],
};

__END__

=== Google Maps 1
--- input
<iframe width="425" height="350" frameborder="no" scrolling="no" marginheight="0" marginwidth="0" src="http://maps.google.com/?ie=UTF8&z=16&om=1&ll=37.371384,-122.086353&output=embed&s=AARTsJqzARj-Z8VnW5pkPMLMmZbqrJcYpw"></iframe>
--- expected
Google Maps

=== Google Maps 2
--- input
<iframe width="425" height="350" frameborder="no" scrolling="no" marginheight="0" marginwidth="0" src="http://maps.google.com/maps?f=q&hl=ja&geocode=&q=%E6%B8%8B%E8%B0%B7&ie=UTF8&ll=35.66671,139.705582&spn=0.006939,0.014591&z=14&iwloc=addr&om=1&output=embed&s=AARTsJoPYtZh3xfr6tziFXtC1r8XJ8oT_A"></iframe>
--- expected
Google Maps

=== Google Maps 3
--- input
<iframe width="425" height="350" frameborder="no" scrolling="no" marginheight="0" marginwidth="0" src="http://maps.google.co.jp/maps/ms?ie=UTF8&oe=UTF-8&hl=ja&om=1&msa=0&msid=112084939017035340025.0004367314da89a1b1374&ll=35.657916,139.735391&spn=0.020167,0.019258&output=embed&s=AARTsJp6xLWSnjjSRlCh8K4ZAnReNQTQow"></iframe>
--- expected
Google Maps

=== Google Maps 4
--- input
<iframe width="425" height="350" frameborder="0" scrolling="no" marginheight="0" marginwidth="0" src="http://maps.google.co.jp/maps/ms?ie=UTF8&amp;om=1&amp;s=AARTsJqo3_npS5_fuMzNCAbcLlqrL989ow&amp;msa=0&amp;msid=106805216862774454869.00043a78badcc5a66ff1d&amp;ll=35.637627,139.690003&amp;spn=0.012207,0.018239&amp;z=15&amp;output=embed"></iframe>
--- expected
Google Maps

=== Google Maps 5
--- input
<iframe width="425" height="350" frameborder="0" scrolling="no" marginheight="0" marginwidth="0" src="http://maps.google.co.jp/maps?f=q&amp;hl=ja&amp;geocode=&amp;time=&amp;date=&amp;ttype=&amp;q=%E6%9D%B1%E4%BA%AC%E9%83%BD%E7%9B%AE%E9%BB%92%E5%8C%BA%E7%A5%90%E5%A4%A9%E5%AF%BA2-15-16&amp;ie=UTF8&amp;ll=35.644045,139.694166&amp;spn=0.007098,0.01502&amp;z=14&amp;iwloc=addr&amp;om=1&amp;output=embed&amp;s=AARTsJp9lRG5Absc7YHC-8U17p7pOeh54Q"></iframe>
--- expected
Google Maps
