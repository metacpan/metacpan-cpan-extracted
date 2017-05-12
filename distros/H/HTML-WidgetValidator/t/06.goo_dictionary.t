use Test::Base;
use HTML::WidgetValidator;

sub validate {
  my $validateor = HTML::WidgetValidator->new(widgets => [ 'GooDictionary' ]);
  my $result  = $validateor->validate(shift);
  return $result ? $result->name : ' ';
}

filters {
    input    => [qw/chomp validate/],
    expected => [qw/chomp/],
};

__END__

=== Goo Dictionary 1
--- input
<script src="http://dictionary.goo.ne.jp/dictionary/blog_parts/js/blog_search_pink.js" charset="euc-jp"></script>
--- expected
Goo Dictionary

=== Goo Dictionary 2
--- input
<script src="http://dictionary.goo.ne.jp/dictionary/blog_parts/js/blog_search_orange.js" charset="euc-jp"></script>
--- expected
Goo Dictionary
