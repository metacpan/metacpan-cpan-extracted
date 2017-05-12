use Test::Base;
use HTML::WidgetValidator;

sub validate {
  my $validateor = HTML::WidgetValidator->new(widgets => [ 'RakugakiBoard' ]);
  my $result  = $validateor->validate(shift);
  return $result ? $result->name : ' ';
}

filters {
    input    => [qw/chomp validate/],
    expected => [qw/chomp/],
};

__END__

=== Rakugaki Board script
--- input
<script language="javascript" src="http://rakugaki.kayac.com/rakugaki_tag.php?rid=52113"></script>
--- expected
Rakugaki Board

=== Rakugaki Board noscript
--- input
<noscript><a href="http://www.blogdeco.jp/" target="_blank"><img src="http://www.blogdeco.jp/img/jsWarning.gif" width="140" height="140" border="0" alt="Blogdeco" /></a></noscript>
--- expected
Rakugaki Board
