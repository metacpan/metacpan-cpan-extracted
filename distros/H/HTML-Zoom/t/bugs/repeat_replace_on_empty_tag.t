use strictures 1;
use Test::More skip_all => 'TODO test';

use HTML::Zoom;

my $tmpla = <<END;
<body>
  <div class="main"></div>
</body>
END


my $tmplb = <<END;
<body>
  <div class="main" />
</body>
END

my $ra = HTML::Zoom->from_html( $tmpla )->select('.main')->repeat( [
    sub{
        $_->select('div')->replace_content('foo');
    }
])->to_html;

like( $ra, qr^<div class="main">foo</div>^ );


my $rb = HTML::Zoom->from_html( $tmplb )->select('.main')->repeat( [
    sub{
        $_->select('div')->replace_content('foo');
    }
])->to_html;

like( $rb, qr^<div class="main">foo</div>^);

done_testing;
