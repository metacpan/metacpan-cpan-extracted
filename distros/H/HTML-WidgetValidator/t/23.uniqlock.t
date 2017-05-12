use Test::Base;
use HTML::WidgetValidator;

sub validate {
  my $validateor = HTML::WidgetValidator->new(widgets => [ 'Uniqlock' ]);
  my $result  = $validateor->validate(shift);
  return $result ? $result->name : ' ';
}

filters {
    input    => [qw/chomp validate/],
    expected => [qw/chomp/],
};

__END__

=== Uniqlock 1
--- input
<script type="text/javascript" src="http://www.uniqlo.jp/uniqlock/user/js/Cw1f4EBePHf5vzv1.js"></script>
--- expected
UNIQLOCK

=== Uniqlock 2
--- input
<script type="text/javascript" src="http://www.uniqlo.jp/uniqlock/user/js/FYMuZ9wn3MOtsBrm.js"></script>
--- expected
UNIQLOCK
