use Test::Base;
use HTML::WidgetValidator;

sub validate {
  my $validateor = HTML::WidgetValidator->new(widgets => [ 'AmazonJP' ]);
  my $result  = $validateor->validate(shift);
  return $result ? $result->name : ' ';
}

filters {
    input    => [qw/chomp validate/],
    expected => [qw/chomp/],
};



__END__

=== AmazonJP 1
--- input
<iframe src="http://rcm-jp.amazon.co.jp/e/cm?t=daql-22&o=9&p=6&l=st1&mode=books-jp&search=%E6%97%A5%E6%9C%AC%E8%AA%9E&fc1=000000&lt1=&lc1=3366FF&bg1=FFFFFF&f=ifr" marginwidth="0" marginheight="0" width="120" height="150" border="0" frameborder="0" style="border:none;" scrolling="no"></iframe>
--- expected
AmazonJP

=== AmazonJP 2
--- input
<iframe src="http://rcm-jp.amazon.co.jp/e/cm?t=daql-22&o=9&p=6&l=st1&mode=books-jp&search=%E6%97%A5%E6%9C%AC%E8%AA%9E&fc1=000000&lt1=_top&lc1=3366FF&bg1=FFFFFF&f=ifr" marginwidth="0" marginheight="0" width="120" height="150" border="0" frameborder="0" style="border:none;" scrolling="no"></iframe>
--- expected
AmazonJP

=== AmazonJP 3
--- input
<iframe src="http://rcm-jp.amazon.co.jp/e/cm?t=daql-22&o=9&p=6&l=st1&mode=books-jp&search=%E6%97%A5%E6%9C%AC%E8%AA%9E&fc1=000000&lt1=_top&lc1=3366FF&bg1=FFFFFF&f=ifr" marginwidth="0" marginheight="0" width="120" height="150" border="0" frameborder="0" style="border:none;" scrolling="no"></iframe>
--- expected
AmazonJP

=== AmazonJP 4
--- input
<iframe src="http://rcm-jp.amazon.co.jp/e/cm?t=daql-22&o=9&p=6&l=st1&mode=books-jp&search=%E6%97%A5%E6%9C%AC%E8%AA%9E&fc1=000000&lt1=_blank&lc1=3366FF&bg1=FFFFFF&npa=1&f=ifr" marginwidth="0" marginheight="0" width="120" height="150" border="0" frameborder="0" style="border:none;" scrolling="no"></iframe>
--- expected
AmazonJP

=== AmazonJP 5
--- input
<iframe src="http://rcm-jp.amazon.co.jp/e/cm?t=daql-22&o=9&p=6&l=st1&mode=dvd-jp&search=SF&fc1=000000&lt1=_blank&lc1=3366FF&bg1=FFFFFF&f=ifr" marginwidth="0" marginheight="0" width="120" height="150" border="0" frameborder="0" style="border:none;" scrolling="no"></iframe>
--- expected
AmazonJP

=== AmazonJP 6
--- input
<iframe src="http://rcm-jp.amazon.co.jp/e/cm?t=daql-22&o=9&p=6&l=bn1&mode=electronics-jp&browse=3210981&fc1=000000&lt1=_blank&lc1=3366FF&bg1=FFFFFF&f=ifr" marginwidth="0" marginheight="0" width="120" height="150" border="0" frameborder="0" style="border:none;" scrolling="no"></iframe>
--- expected
AmazonJP

=== AmazonJP 7
--- input
<iframe src="http://rcm-jp.amazon.co.jp/e/cm?t=daql-22&o=9&p=8&l=st1&mode=books-jp&search=%E6%97%A5%E6%9C%AC%E8%AA%9E&fc1=000000&lt1=&lc1=3366FF&bg1=FFFFFF&f=ifr" marginwidth="0" marginheight="0" width="120" height="240" border="0" frameborder="0" style="border:none;" scrolling="no"></iframe>
--- expected
AmazonJP

=== AmazonJP 8
--- input
<iframe src="http://rcm-jp.amazon.co.jp/e/cm?t=daql-22&o=9&p=6&l=st1&mode=books-jp&search=%E6%97%A5%E6%9C%AC%E8%AA%9E&fc1=000000&lt1=&lc1=3366FF&bg1=FFFFFF&f=ifr" marginwidth="0" marginheight="0" width="120" height="150" border="0" frameborder="0" style="border:none;" scrolling="no"></iframe>
--- expected
AmazonJP

=== AmazonJP 9
--- input
<iframe src="http://rcm-jp.amazon.co.jp/e/cm?t=daql-22&o=9&p=10&l=st1&mode=books-jp&search=%E6%97%A5%E6%9C%AC%E8%AA%9E&fc1=000000&lt1=&lc1=3366FF&bg1=FFFFFF&f=ifr" marginwidth="0" marginheight="0" width="120" height="450" border="0" frameborder="0" style="border:none;" scrolling="no"></iframe>
--- expected
AmazonJP

=== AmazonJP 10
--- input
<iframe src="http://rcm-jp.amazon.co.jp/e/cm?t=daql-22&o=9&p=11&l=st1&mode=books-jp&search=%E6%97%A5%E6%9C%AC%E8%AA%9E&fc1=000000&lt1=&lc1=3366FF&bg1=FFFFFF&f=ifr" marginwidth="0" marginheight="0" width="120" height="600" border="0" frameborder="0" style="border:none;" scrolling="no"></iframe>
--- expected
AmazonJP

=== AmazonJP 11
--- input
<iframe src="http://rcm-jp.amazon.co.jp/e/cm?t=daql-22&o=9&p=12&l=st1&mode=books-jp&search=%E6%97%A5%E6%9C%AC%E8%AA%9E&fc1=000000&lt1=&lc1=3366FF&bg1=FFFFFF&f=ifr" marginwidth="0" marginheight="0" width="300" height="250" border="0" frameborder="0" style="border:none;" scrolling="no"></iframe>
--- expected
AmazonJP

=== AmazonJP 12
--- input
<iframe src="http://rcm-jp.amazon.co.jp/e/cm?t=daql-22&o=9&p=13&l=st1&mode=books-jp&search=%E6%97%A5%E6%9C%AC%E8%AA%9E&fc1=000000&lt1=&lc1=3366FF&bg1=FFFFFF&f=ifr" marginwidth="0" marginheight="0" width="468" height="60" border="0" frameborder="0" style="border:none;" scrolling="no"></iframe>
--- expected
AmazonJP

=== AmazonJP 13
--- input
<iframe src="http://rcm-jp.amazon.co.jp/e/cm?t=daql-22&o=9&p=14&l=st1&mode=books-jp&search=%E6%97%A5%E6%9C%AC%E8%AA%9E&fc1=000000&lt1=&lc1=3366FF&bg1=FFFFFF&f=ifr" marginwidth="0" marginheight="0" width="160" height="600" border="0" frameborder="0" style="border:none;" scrolling="no"></iframe>
--- expected
AmazonJP

=== AmazonJP 14
--- input
<iframe src="http://rcm-jp.amazon.co.jp/e/cm?t=daql-22&o=9&p=15&l=st1&mode=books-jp&search=%E6%97%A5%E6%9C%AC%E8%AA%9E&fc1=000000&lt1=&lc1=3366FF&bg1=FFFFFF&f=ifr" marginwidth="0" marginheight="0" width="468" height="240" border="0" frameborder="0" style="border:none;" scrolling="no"></iframe>
--- expected
AmazonJP

=== AmazonJP 15
--- input
<iframe src="http://rcm-jp.amazon.co.jp/e/cm?t=daql-22&o=9&p=16&l=st1&mode=books-jp&search=%E6%97%A5%E6%9C%AC%E8%AA%9E&fc1=000000&lt1=&lc1=3366FF&bg1=FFFFFF&f=ifr" marginwidth="0" marginheight="0" width="468" height="336" border="0" frameborder="0" style="border:none;" scrolling="no"></iframe>
--- expected
AmazonJP

=== AmazonJP 16
--- input
<iframe src="http://rcm-jp.amazon.co.jp/e/cm?t=daql-22&o=9&p=30&l=st1&mode=books-jp&search=%E6%97%A5%E6%9C%AC%E8%AA%9E&fc1=000000&lt1=&lc1=3366FF&bg1=FFFFFF&f=ifr" marginwidth="0" marginheight="0" width="350" height="600" border="0" frameborder="0" style="border:none;" scrolling="no"></iframe>
--- expected
AmazonJP

=== AmazonJP 17
--- input
<iframe src="http://rcm-jp.amazon.co.jp/e/cm?t=daql-22&o=9&p=48&l=st1&mode=books-jp&search=%E6%97%A5%E6%9C%AC%E8%AA%9E&fc1=000000&lt1=&lc1=3366FF&bg1=FFFFFF&f=ifr" marginwidth="0" marginheight="0" width="728" height="90" border="0" frameborder="0" style="border:none;" scrolling="no"></iframe>
--- expected
AmazonJP
