use strict;
use Plack::App::File;
use HTML::Highlighter;
use Test::More;
use Plack::Test;
use HTTP::Request::Common;

my $file = Plack::App::File->new(root => "t");
my $html = do   {
  local $/; 
  open my $highlighted, '<', 't/foo-highlighted.html';
  <$highlighted>;
};

# get the highlight from a param
#
my $app = HTML::Highlighter->wrap($file, param => "search");

test_psgi $app, sub {
  my $cb = shift;

  my $res = $cb->(GET "/foo.html?search=foo");
  is $res->code, 200;
  ok $res->content eq $html;
};

# set highlight in callback
#
$app = HTML::Highlighter->wrap($file, callback => sub {
    my $env = shift;
    $env->{'psgix.highlight'} = "foo";
});

test_psgi $app, sub {
  my $cb = shift;

  my $res = $cb->(GET "/foo.html");
  is $res->code, 200;
  ok $res->content eq $html;
};

# defaults
#
$app = HTML::Highlighter->wrap($file);

test_psgi $app, sub {
  my $cb = shift;

  my $res = $cb->(GET "/foo.html?highlight=foo");
  is $res->code, 200;
  ok $res->content eq $html;

  $res = $cb->(GET "/foo.html?q=foo");
  is $res->code, 200;
  ok $res->content eq $html;

  $res = $cb->(GET "/foo.html?query=foo");
  is $res->code, 200;
  ok $res->content eq $html;

  $res = $cb->(GET "/foo.html?search=foo");
  is $res->code, 200;
  ok $res->content eq $html;
};

done_testing();
