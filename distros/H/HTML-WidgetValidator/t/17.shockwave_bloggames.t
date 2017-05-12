use Test::Base;
use HTML::WidgetValidator;

sub validate {
  my $validateor = HTML::WidgetValidator->new(widgets => [ 'ShockwaveBloggames' ]);
  my $result  = $validateor->validate(shift);
  return $result ? $result->name : ' ';
}

filters {
    input    => [qw/chomp validate/],
    expected => [qw/chomp/],
};

__END__

=== Shockwave Bloggames 1
--- input
<script type="text/javascript" language = "javascript" src="http://www.shockwave.co.jp/bloggame/blogame.php?idu=OTExOTk0Ng==&dtreg=MjAwNy8wOC8yNA==&typ=s&nmgb=Yl9zbHlkZXJwdXp6bGU=" charset = "UTF-8"></script>
--- expected
Shockwave Bloggames


=== Shockwave Bloggames 2
--- input
<script type="text/javascript" language = "javascript" src="http://www.shockwave.co.jp/bloggame/blogame.php?idu=OTExOTk0Ng==&dtreg=MjAwNy8wOC8yNA==&typ=s&nmgb=Yl9uYW1pbm9yaV9z" charset = "UTF-8"></script>
--- expected
Shockwave Bloggames

=== Shockwave Bloggames 3
--- input
<script type="text/javascript" language = "javascript" src="http://www.shockwave.co.jp/bloggame/blogame.php?idu=OTExOTk0Ng==&dtreg=MjAwNy8wOC8yNA==&typ=e&nmgb=Yl9uYW1pbm9yaV9l" charset = "UTF-8"></script>
--- expected
Shockwave Bloggames
