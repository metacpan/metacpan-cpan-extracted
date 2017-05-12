use Test::Base;
use HTML::WidgetValidator;

sub validate {
  my $validator = HTML::WidgetValidator->new(widgets => [ 'ToyotaIst' ]);
  my $result = $validator->validate(shift);
  return $result ? $result->name : ' ';
}

filters {
    input    => [qw/chomp validate/],
    expected => [qw/chomp/],
};

__END__

=== IST script
--- input
<script src="http://ist.blogdeco.jp/js/istbp.js?id=1187877795820&color=white" charset="utf-8" type="text/javascript"></script>
--- expected
Toyota IST

=== IST noscript
--- input
<noscript><a href="http://www.blogdeco.jp/" target="_blank"><img src="http://www.blogdeco.jp/img/jsWarning.gif" width="140" height="140" border="0" alt="Blogdeco" /></a></noscript>
--- expected
Toyota IST
