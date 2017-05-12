use strict;
use warnings FATAL => 'all';

use HTML::Zoom;
use HTML::Zoom::CodeStream;

use Test::More;


# turns iterator into stream
sub code_stream (&) {
  my $code = shift;
  return sub {
    HTML::Zoom::CodeStream->new({
      code => $code,
    });
  }
}

my $tmpl = <<'TMPL';
<body>
  <div class="item">
    <div class="item-name"></div>
  </div>
</body>
TMPL

my $zoom = HTML::Zoom->new( { zconfig => { parser => 'HTML::Zoom::Parser::HH5P' } } )->from_html($tmpl);
my @list = qw(foo bar baz);

foreach my $flush (0..1) {

  # from HTML::Zoom manpage, slightly modified
  my $z2 = $zoom->select('.item')->repeat(code_stream {
    if (my $name = shift @list) {
      return sub { $_->select('.item-name')->replace_content($name) }
    } else {
      return
    }
  }, { flush_before => $flush });

  my $fh = $z2->to_fh;
  my $lineno = 0;
  while (my $chunk = $fh->getline) {
    $lineno++;
    # debugging here
  }

  cmp_ok($lineno, '==', 1+$flush, "flush_before => $flush is $lineno chunks");
}

done_testing;
