use Test::More tests=> 38;
use lib qw( ./lib ../lib );
use Egg::Helper;

ok my $e= Egg::Helper->run( Vtest=> { vtest_plugins=> [qw/ Filter /] }),
   q{load plugin.};

can_ok $e, 'filter';
  ok my $pm= $e->req->params, q{$pm= $e->req->params};

%$pm= (
  trim        => "  \n  123  \n  ",
  hold        => "\r\n1\t\n2\n\n3",
  hold_crlf   => "\n1\n\n2\n\n3\n",
  hold_tab    => "\t\t1\t2\t3\t\t",
  hold_blank  => " \n1  2  3\n  ",
  hold_html   => "<tag>123</tag>",
  strip       => "\n\n1\n\n2\n\n",
  strip_blank => "   1   2  3   ",
  strip_tab   => "\t1\t\t2\t3\t\t",
  strip_html  => "<tag>123</tag>",
  strip_crlf  => "\n1\n\n2\n3\n\n",
  crlf1       => "\n\n\n1\n\n\n2\n\n\n3\n\n\n",
  crlf2       => "\n\n\n\n\n\n1\n\n\n\n\n\n2\n\n\n\n\n\n\n\n\n3\n\n\n\n\n\n",
  escape_html => "<tag>123</tag>",
  digit       => "1t2e3s4t5",
  alphanum    => "(test)[1,234]",
  integer     => "12345",
  pos_integer => "+12345",
  neg_integer => "-12345",
  decimal     => "1.2345",
  pos_decimal => "+1.2345",
  neg_decimal => "-1.2345",
  dollars     => "123.45",
  phone       => "ABC123(DEF456)GHI789#01",
  sql_wildcard=> '*test*',
  quotemeta   => '@test@',
  uc          => 'test',
  ucfirst     => 'test',
  lc          => 'TEST',
  lc_email    => 'MYname@MyDomainName.com',
  uri         => 'http://MyDomainName.com/HomePage.html',
  regex1      => '0123456789',
  regex2      => 'abc0123abc456789',
  );

ok $e->filter(
  trim        => [qw/trim/],
  hold        => [qw/hold/],
  hold_crlf   => [qw/hold_crlf/],
  hold_tab    => [qw/hold_tab/],
  hold_blank  => [qw/hold_blank/],
  hold_html   => [qw/hold_html/],
  strip       => [qw/strip/],
  strip_blank => [qw/strip_blank/],
  strip_tab   => [qw/strip_tab/],
  strip_html  => [qw/strip_html/],
  strip_crlf  => [qw/strip_crlf/],
  crlf1       => [qw/crlf[2]/],
  crlf2       => [qw/crlf[3]/],
  escape_html => [qw/escape_html/],
  digit       => [qw/digit/],
  alphanum    => [qw/alphanum/],
  integer     => [qw/integer/],
  pos_integer => [qw/pos_integer/],
  neg_integer => [qw/neg_integer/],
  decimal     => [qw/decimal/],
  pos_decimal => [qw/pos_decimal/],
  neg_decimal => [qw/neg_decimal/],
  dollars     => [qw/dollars/],
  phone       => [qw/phone/],
  sql_wildcard=> [qw/sql_wildcard/],
  quotemeta   => [qw/quotemeta/],
  uc          => [qw/uc/],
  ucfirst     => [qw/ucfirst/],
  lc          => [qw/lc/],
  lc_email    => [qw/lc_email/],
  uri         => [qw/uri/],
  regex1      => [q{regex['3456']}],
  regex2      => [q{regex['^abc','789$']}],
  "regex[qw/ regex1 regex2 /]"=> [q{regex['abc','[02468]']}],
  ), q{$e->filter( ..... };

like $pm->{trim}, qr{^123$}, q{$pm->{trim}};
like $pm->{hold}, qr{^123$}, q{$pm->{hold}};
like $pm->{hold_crlf}, qr{^123$}, q{$pm->{hold_crlf}};
like $pm->{hold_tab}, qr{^123$}, q{$pm->{hold_tab}};
like $pm->{hold_blank}, qr{^\n123\n$}, q{$pm->{hold_blank}};
like $pm->{hold_html}, qr{^123$}, q{$pm->{hold_html}};
like $pm->{strip}, qr{^ 1 2 $}, q{$pm->{strip}};
like $pm->{strip_blank}, qr{^ 1 2 3 $}, q{$pm->{strip_blank}};
like $pm->{strip_tab}, qr{^ 1 2 3 $}, q{$pm->{strip_tab}};
like $pm->{strip_html}, qr{^ 123 $}, q{$pm->{strip_html}};
like $pm->{strip_crlf}, qr{^ 1 2 3 $}, q{$pm->{strip_crlf}};
like $pm->{crlf1}, qr{^\n\n1\n\n2\n\n3\n\n$}, q{$pm->{crlf1}};
like $pm->{crlf2}, qr{^\n\n\n1\n\n\n2\n\n\n3\n\n\n$}, q{$pm->{crlf2}};
like $pm->{escape_html}, qr{^&lt\;tag&gt\;123&lt\;/tag&gt\;$}, q{$pm->{escape_html}};
like $pm->{digit}, qr{^12345$}, q{$pm->{digit}};
like $pm->{alphanum}, qr{^test1234$}, q{$pm->{alphanum}};
like $pm->{integer}, qr{^12345$}, q{$pm->{integer}};
like $pm->{pos_integer}, qr{^\+12345$}, q{$pm->{pos_integer}};
like $pm->{neg_integer}, qr/^\-12345$/, q{$pm->{neg_integer}};
like $pm->{decimal}, qr/^1\.2345$/, q{$pm->{decimal}};
like $pm->{pos_decimal}, qr/^\+1\.2345$/, q{$pm->{pos_decimal}};
like $pm->{neg_decimal}, qr/^\-1\.2345$/, q{$pm->{neg_decimal}};
like $pm->{dollars}, qr/^123\.45$/, q{$pm->{dollars}};
like $pm->{phone}, qr/^123\(456\)789\#01$/, q{$pm->{phone}};
like $pm->{sql_wildcard}, qr/^\%test\%$/, q{$pm->{sql_wildcard}};
like $pm->{quotemeta}, qr/^\\\@test\\\@$/, q{$pm->{quotemeta}};
like $pm->{uc}, qr/^TEST$/, q{$pm->{uc}};
like $pm->{ucfirst}, qr/^Test$/, q{$pm->{ucfirst}};
like $pm->{lc}, qr/^test$/, q{$pm->{lc}};
like $pm->{lc_email}, qr/^MYname\@mydomainname\.com$/, q{$pm->{lc_email}};
like $pm->{uri}, qr{^http\://mydomainname.com/HomePage\.html$}, q{$pm->{uri}};
like $pm->{regex1}, qr{^012789$}, q{$pm->{regex1}};
like $pm->{regex2}, qr{^0123abc456$}, q{$pm->{regex2}};
like $pm->{regex}, qr{^179135$}, q{$pm->{regex}};
