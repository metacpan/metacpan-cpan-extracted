use KeywordsSpider::Core;
use Test::Spec;
use Test::MockObject;
use Test::Spec::Mocks;
use HTML::TreeBuilder;

describe "KeywordsSpider::Core" => sub {
  my $string = q{};
  open my ($fh), '>', \$string;

  my $url = 'http://domain.sk/base.html';

  my @keywords = qw/child abuse death pussy/;

  my %allowed_keywords = (
    child => 1,
    pussy => 1,
  );

  my $debug = 1;
  my $web_depth = 5;

  # links are changed so we give them to each spider separately
  my %spider_params = (
    output_file => $fh,
    keywords => \@keywords,
    allowed_keywords => \%allowed_keywords,
    debug_enabled => $debug,
    web_depth => $web_depth,
  );

  my $url_params = {
    'want_spider' => 1,
    'fetched' => 0,
    'depth' => 0,
  };

  it "loads ok" => sub {
    pass;
  };

  it "error response" => sub {
    my $spider = KeywordsSpider::Core->new(
      %spider_params,
      links => {$url => $url_params,},
    );

    my $response = Test::MockObject->new();
    $response->set_false('is_success')
      ->set_always('status_line', 400);

    LWP::UserAgent->expects('request')->returns($response)->at_least(1);

    $spider->spider_links();

    like($spider->output, qr/ERROR:400/);
  };

  it "adds a link" => sub {
    my $html = <<EF;
<html>
<head>
</head>
<body>
  <a href="trala.html"></a>
</body>
</html>
EF

    my $root = HTML::TreeBuilder->new_from_content($html);

    my $spider = KeywordsSpider::Core->new(
      %spider_params,
      links => {$url => $url_params,},
      root => $root,
    );

    my $depth = 1;
    $spider->add_links_from_root($depth, $url);

    is(defined $spider->links->{'http://domain.sk/trala.html'}, 1);
  };

  it "does not add link from another domain" => sub {
    my $html = <<EF;
<html>
<head>
</head>
<body>
  <a href="http://duomain.sk/trala.html"></a>
</body>
</html>
EF

    my $root = HTML::TreeBuilder->new_from_content($html);

    my $spider = KeywordsSpider::Core->new(
      %spider_params,
      links => {$url => $url_params,},
      root => $root,
      origin_domain => 'domain.sk',
    );

    my $depth = 1;
    $spider->add_links_from_root($depth, $url);

    is(defined $spider->links->{'http://duomain.sk/trala.html'}, '');
  };

  describe "check_website" => sub {
    my $OK = 0;
    my $ALERT = 1;

    it "OKs" => sub {
      my $html = <<HTMLEND;
        <html>
        <head>
        </head>
        <body>
          tralala trololo
        </body>
        </html>
HTMLEND

      my $root = HTML::TreeBuilder->new_from_content($html);

      my $spider = KeywordsSpider::Core->new(
        %spider_params,
        links => {$url => $url_params,},
        root => $root,
      );

      is($spider->check_website($url), $OK);
    };

    it "ALERTs" => sub {
      my $html = <<HTMLEND;
        <html>
        <head>
          <meta name="keywords" content="pussy">
        </head>
        <body>
          tralala death trololo
        </body>
        </html>
HTMLEND

      my $root = HTML::TreeBuilder->new_from_content($html);

      my $spider = KeywordsSpider::Core->new(
        %spider_params,
        links => {$url => $url_params,},
        root => $root,
      );

      is($spider->check_website($url), $ALERT);

      like($spider->output, qr/ALERT possible bad content $url death pussy/);
      like($spider->output, qr/found keywords: 2/);
    };
  };

  it "uses defaults if not specified" => sub {
    my $spider = KeywordsSpider::Core->new(
      output_file => $fh,
      links => {$url => $url_params,},
      keywords => \@keywords,
    );

    is($spider->debug_enabled, 0);
    is($spider->web_depth, 3);
  };
};

runtests;
