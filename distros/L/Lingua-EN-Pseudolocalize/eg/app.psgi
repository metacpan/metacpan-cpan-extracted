# A test app to try out the conversion effects in a browser.
# Usage:
# > plackup eg/app.psgi

use 5.14.0;
use Plack::Builder;
use Plack::Request;
use Encode 'encode_utf8';
use Template;
use lib 'lib';
use Lingua::EN::Pseudolocalize  qw(convert deconvert);

my $template = '<html><body>
<h1>Pseudolocalize!</h1>
<form action="/" method="POST">
<textarea name="text" rows="10" cols="30">
[% og_text %]
</textarea>
<input type="submit" value="Convert" />
</form>
[% text.split("\n").join("<br>") %]
</body></html>';

my $test_string = 'first line
second line
third one
Wes Malone, a hoopy frood
hello world
ETAOIN SHRDLU
jcvd might pique a sleazy boxer with funk
the quick onyx goblin jumps over the lazy dwarf';

builder {
   mount '/' => sub {
      my $req = Plack::Request->new(shift);
      my $str = $req->param('text') || $test_string;
      my $body;
      Template->new->process(\$template, {
         og_text => $str,
         text => convert $str,
      }, \$body);

      my $res = $req->new_response(200);
      $res->content_type('text/html; charset=utf-8');
      $res->body(encode_utf8 $body);
      $res->finalize;
   }
};

# vim:ft=perl
