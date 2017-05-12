use Test::Base;
use HTML::WidgetValidator;

sub validate {
  my $validateor = HTML::WidgetValidator->new(widgets => [ 'Playlog' ]);
  my $result  = $validateor->validate(shift);
  return $result ? $result->name : ' ';
}

filters {
    input    => [qw/chomp validate/],
    expected => [qw/chomp/],
};

__END__

=== Playlog 1
--- input
<script language="JavaScript" src="http://playlog.jp/bp/js/64/208de87a4a437dff11de2bdb8b035f2a.js" ></script>
--- expected
Playlog

=== Playlog 2
--- input
<script language="JavaScript" src="http://playlog.jp/bp/js/65/e653887b79b20d58420b97f729a08f37.js" ></script>
--- expected
Playlog
