use Test::Base;
use HTML::WidgetValidator;

sub validate {
  my $validateor = HTML::WidgetValidator->new(widgets => [ 'Rilakkuma' ]);
  my $result  = $validateor->validate(shift);
  return $result ? $result->name : ' ';
}

filters {
    input    => [qw/chomp validate/],
    expected => [qw/chomp/],
};

__END__

=== Rilakkuma
--- input
<script language="JavaScript" type="text/javascript" src="http://www.san-xchara.jp/js/6405dd2083f1ad2790b5eab26890f44b.js"></script>
--- expected
Rilakkuma
