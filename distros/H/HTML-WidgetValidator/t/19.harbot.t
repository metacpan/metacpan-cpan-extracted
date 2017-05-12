use Test::Base;
use HTML::WidgetValidator;

sub validate {
  my $validateor = HTML::WidgetValidator->new(widgets => [ 'Harbot' ]);
  my $result  = $validateor->validate(shift);
  return $result ? $result->name : ' ';
}

filters {
    input    => [qw/chomp validate/],
    expected => [qw/chomp/],
};

__END__

=== Harbot 1
--- input
<script language="JavaScript" src="http://harbox-harbot.so-net.ne.jp/h.jsp?hbxid=483679"></script>
--- expected
Harbot

=== Harbot 2
--- input
<script language="JavaScript" src="http://harbox-harbot.so-net.ne.jp/h.jsp?hbxid=483678"></script>
--- expected
Harbot
