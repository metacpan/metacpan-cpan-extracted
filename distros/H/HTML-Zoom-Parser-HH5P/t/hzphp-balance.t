use strictures 1;
use Test::More;
use HTML::Zoom;

sub wsis {
	my $got      = shift;
	my $expected = shift;
	s/\s//gs for $got, $expected;
	unshift @_, $got, $expected;
	goto \&is;
}

my $z = HTML::Zoom->new( { zconfig => { parser => 'HTML::Zoom::Parser::HH5P' } } )
                  ->from_html(q{<html>
  <body>
    <div class="outer">
      <div class="inner"><span /></div>
    </div>
  </body>
</html>});

wsis(
  $z->select('.outer')
    ->collect_content({
       filter => sub { $_->select('.inner')->replace_content('bar!') },
       passthrough => 1
      })
    ->to_html,
  q{<html>
  <body>
    <div class="outer">
      <div class="inner">bar!</div>
    </div>
  </body>
</html>},
  "filter within collect works ok"
);

done_testing;
